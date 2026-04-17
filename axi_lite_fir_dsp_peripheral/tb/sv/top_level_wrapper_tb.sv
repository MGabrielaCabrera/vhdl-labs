`include "tb_utils.svh"
`include "interfaces/axi_lite_if.sv"
`include "interfaces/external_dsp_if.sv"
`include "classes/axi_driver.sv"
`include "classes/scoreboard.sv"

// Top testbench for AXI Lite Slave Interface
`timescale 1ns/1ps
module top_level_wrapper_tb;

    // Clock and reset generation
   bit clk, rst_n;
   always #5 clk = ~clk; // 100 MHz clock

   initial begin
      @(posedge clk);
      rst_n = 0;
      #20 rst_n = 1; // Release reset after 20 ns
   end

   // Instantiate the AXI Lite interface
   axi_lite_if axi_if(clk, rst_n);

   // Instantiate the external DSP interface
   external_dsp_if dsp_if(clk, rst_n);

   // Instantiate the testbench program
   test axi_tb(axi_if.TB, dsp_if.TB);

   // Instantiate the DUT (Device Under Test)
   top_level_wrapper dut (
      .clk(clk),
      .rst_n(rst_n),
      // Connect AXI Lite interface
      .s_axi_awaddr(axi_if.awaddr),
      .s_axi_awvalid(axi_if.awvalid),
      .s_axi_awready(axi_if.awready),
      .s_axi_wdata(axi_if.wdata),
      .s_axi_wvalid(axi_if.wvalid),
      .s_axi_wready(axi_if.wready),
      .s_axi_wstrb(axi_if.wstrb),
      .s_axi_bresp(axi_if.bresp),
      .s_axi_bvalid(axi_if.bvalid),
      .s_axi_bready(axi_if.bready),
      .s_axi_araddr(axi_if.araddr),
      .s_axi_arvalid(axi_if.arvalid),
      .s_axi_arready(axi_if.arready),
      .s_axi_rdata(axi_if.rdata),
      .s_axi_rresp(axi_if.rresp),
      .s_axi_rvalid(axi_if.rvalid),
      .s_axi_rready(axi_if.rready),
      // Connect external DSP interface
      .dsp_data_in(dsp_if.dsp_data_in),
      .dsp_data_out(dsp_if.dsp_data_out),
      .dsp_enable(dsp_if.dsp_enable),
      .dsp_reset(dsp_if.dsp_reset),
      .dsp_mode(dsp_if.dsp_mode),
      .dsp_data_in_valid(dsp_if.dsp_data_in_valid),
      .dsp_data_in_ready(dsp_if.dsp_data_in_ready),
      .dsp_data_out_valid(dsp_if.dsp_data_out_valid),
      .dsp_data_out_ready(dsp_if.dsp_data_out_ready),
      .dsp_coeff_data(dsp_if.dsp_coeff_data),
      .dsp_coeff_addr(dsp_if.dsp_coeff_addr),
      .dsp_coeff_we(dsp_if.dsp_coeff_we)
   );

   // Instantiate the monitor
   monitor mon(axi_if.MONITOR, dsp_if.MONITOR, clk);


endmodule

module monitor(axi_lite_if.MONITOR axi_if, external_dsp_if.MONITOR dsp_if, input logic clk);

   // Monitor AXI-lite handshakes and data transfers
   always @(posedge clk) begin
      if (axi_if.awvalid && axi_if.awready) begin
         $display("  AXI Write Address: %h", axi_if.awaddr);
      end
      if (axi_if.wvalid && axi_if.wready) begin
         $display("  AXI Write Data: %h, Strb: %b", axi_if.wdata, axi_if.wstrb);
      end
      if (axi_if.bvalid && axi_if.bready) begin
         $display("  AXI Write Response: %b", axi_if.bresp);
      end
      if (axi_if.arvalid && axi_if.arready) begin
         $display("  AXI Read Address: %h", axi_if.araddr);
      end
      if (axi_if.rvalid && axi_if.rready) begin
         $display("  AXI Read Data: %h, Response: %b", axi_if.rdata, axi_if.rresp);
      end
   end
   
   // Monitor DSP interface signals
   always @(posedge clk) begin
      if (dsp_if.dsp_data_in_valid && dsp_if.dsp_data_in_ready) begin
         $display("  DSP Data In: %h", dsp_if.dsp_data_in);
      end
      if (dsp_if.dsp_data_out_valid && dsp_if.dsp_data_out_ready) begin
         $display("  DSP Data Out: %h", dsp_if.dsp_data_out);
      end
/*       if (dsp_if.dsp_enable) begin
         $display("  DSP Enabled");
      end else begin
         $display("DSP Disabled");
      end */
   end

endmodule

/* Testbench to drive the AXI Lite and DSP interfaces: Programs are preferred for testbenches
   because they run in the reactive region, naturally avoiding race conditions by sampling 
   before and driving after the clock edge. However, ModelSim’s free version does not support
   programs, so a module is used instead. To reduce potential race conditions, clocking 
   blocks are implemented within the interfaces.*/
module automatic test(axi_lite_if.TB axi_if, external_dsp_if.TB dsp_if);

   // Testbench variables and tasks
   const int ADDR_CTRL = 32'h00; // Address for control register
   const int ADDR_STATUS = 32'h04; // Address for status register
   const int ADDR_COEFF_DATA = 32'h08; // Address for coefficient data register
   const int ADDR_COEFF_ADDR = 32'h0C; // Address for coefficient address register
   const int ADDR_DATA_IN = 32'h10; // Address for data in register
   const int ADDR_DATA_OUT = 32'h14; // Address for data out register
   const int ADDR_OOB = 32'h40; // Address for out of range access

   AXI_Driver axi_drv = new(axi_if);
   AXI_Transaction axi_tran;
   Scoreboard  scb  = new();

   initial begin
      $timeformat(-9, 0, " ns", 8);

      // Signal initialization
      axi_drv.init();

      dsp_if.cb.dsp_data_in_ready <= 0;
      dsp_if.cb.dsp_data_out_valid <= 0;
      dsp_if.cb.dsp_data_out <= 0;
   
      /*---------------------------------------------------------------
        -- Test 1: Reset state
        -- All AXI output signals must be at their safe defaults while
        -- rst_n is held low.
        ---------------------------------------------------------------*/
      scb.init_test("Test 1: Verifying AXI output reset state");

      axi_drv.wait_cycles(1); 
      scb.check("t1_bvalid", axi_if.cb.bvalid == 0, "bvalid should be 0 after reset");
      scb.check("t1_arready", axi_if.cb.arready == 0, "arready should be 0 after reset");
      scb.check("t1_rvalid", axi_if.cb.rvalid == 0, "rvalid should be 0 after reset");
      scb.check("t1_dsp_enable", dsp_if.cb.dsp_enable == 0, "DSP enable should be 0 after reset");
      scb.check("t1_dsp_reset", dsp_if.cb.dsp_reset == 0, "DSP reset should be 0 after reset");
      scb.check("t1_dsp_data_in_valid", dsp_if.cb.dsp_data_in_valid == 0, "DSP data_in_valid should be 0 after reset");
      scb.check("t1_dsp_data_out_ready", dsp_if.cb.dsp_data_out_ready == 0, "DSP data_out_ready should be 0 after reset");
      scb.check("t1_dsp_coeff_we", dsp_if.cb.dsp_coeff_we == 0, "DSP coeff_we should be 0 after reset");

      scb.test_report("Test 1");

      /*-----------------------------------------------------------------------
        -- Test 2: AXI write to CTRL and readback
        -- Writing enable=1, reset=1, mode="10" via AXI must reach the DSP
        -- outputs and be readable back at address 0x00.
        -- CTRL encoding: bit0=enable, bit1=reset, bit3:2=mode --> 0x0B
      -----------------------------------------------------------------------*/
      scb.init_test("Test 2: AXI write to CTRL and readback");

      axi_tran = new(axi_tran.WRITE, ADDR_CTRL, 32'h0B); // Write to CTRL register
      axi_drv.write(axi_tran);

      // Wait for the DSP interface to reflect the changes
      axi_drv.wait_cycles(1);
      scb.check("t2_dsp_enable", dsp_if.cb.dsp_enable == 1, "DSP enable should be 1 after writing to CTRL");
      scb.check("t2_dsp_reset", dsp_if.cb.dsp_reset == 1, "DSP reset should be 1 after writing to CTRL");
      scb.check("t2_dsp_mode", dsp_if.cb.dsp_mode == 2, "DSP mode should be 2 after writing to CTRL");

      axi_tran = new(axi_tran.READ, ADDR_CTRL); // Read back CTRL register
      axi_drv.read(axi_tran);
      // Sample rdata for checking
      axi_drv.wait_cycles(1);
      scb.check("t2_rdata", axi_if.cb.rdata == 32'h0B,
               $sformatf("Readback data mismatch: expected 0x0B, got %h", axi_if.cb.rdata));

      scb.test_report("Test 2");
 
      /*-----------------------------------------------------------------------
        -- Test 3: CTRL reserved bits are forced to zero
        -- Writing 0xFFFFFFFF to CTRL must only store bits [3:0]; all upper
        -- bits must read back as zero through the full AXI path.
      -----------------------------------------------------------------------*/
      scb.init_test("Test 3: CTRL reserved bits are forced to zero");
      
      axi_tran = new(axi_tran.WRITE, ADDR_CTRL, 32'hFFFFFFFF); // Write to CTRL register
      axi_drv.write(axi_tran);
      axi_tran = new(axi_tran.READ, ADDR_CTRL); // Read back CTRL register
      axi_drv.read(axi_tran);

      // Sample rdata for checking
      axi_drv.wait_cycles(1);
      scb.check("t3_rdata_reserved_bits", axi_if.cb.rdata[31:4] == 28'h00,
               $sformatf("CTRL reserved bits [31:4] must read as zero, got %h", axi_if.cb.rdata[31:4]));
      scb.check("t3_rdata", axi_if.cb.rdata[3:0] == 4'hF,
               $sformatf("CTRL writable bits [3:0] should all be '1', got %h", axi_if.cb.rdata[3:0]));

      // Restore
      axi_tran = new(axi_tran.WRITE, ADDR_CTRL, 32'h00); // Write to CTRL register
      axi_drv.write(axi_tran);

      scb.test_report("Test 3");

      /*-----------------------------------------------------------------------
        -- Test 4: AXI write to CTRL enables DSP (dsp_enable propagation)
        -- Verifies that writing bit 0 of CTRL makes dsp_enable go high, and
        -- clearing it makes it go low again.
      -----------------------------------------------------------------------*/
      scb.init_test("Test 4: CTRL enable bit propagates to dsp_enable");
      
      axi_tran = new(axi_tran.WRITE, ADDR_CTRL, 32'h01); // Set enable bit
      axi_drv.write(axi_tran);

      @(posedge dsp_if.cb);
      scb.check("t4_dsp_enable_set", dsp_if.cb.dsp_enable == 1,
               $sformatf("DSP enable should be 1 after setting enable bit in CTRL"));
      scb.check("t4_dsp_reset_unchanged", dsp_if.cb.dsp_reset == 0,
               $sformatf("DSP reset should remain 0 after setting enable bit in CTRL"));
      scb.check("t4_dsp_mode_unchanged", dsp_if.cb.dsp_mode == 0,
               $sformatf("DSP mode should remain 0 after setting enable bit in CTRL"));
      
      axi_tran = new(axi_tran.WRITE, ADDR_CTRL, 32'h00); // Clear enable bit
      axi_drv.write(axi_tran);
      @(posedge dsp_if.cb);
      scb.check("t4_dsp_enable_clear", dsp_if.cb.dsp_enable == 0,
               $sformatf("DSP enable should be 0 after clearing enable bit in CTRL"));

      scb.test_report("Test 4");
      /*-----------------------------------------------------------------------
        -- T5: AXI write to STATUS is silently ignored (RO register)
        -- STATUS must not change as a result of a software AXI write.
        -- The response must still be OKAY (write accepted by AXI slave).
      -----------------------------------------------------------------------*/
      scb.init_test("Test 5: Verifying STATUS is read-only (AXI write ignored)");

      axi_tran = new(axi_tran.WRITE, ADDR_STATUS, 32'hFFFFFFFF); // Attempt to write to STATUS register
      axi_drv.write(axi_tran);

      // Check that STATUS did not change
      axi_tran = new(axi_tran.READ, ADDR_STATUS); // Read back STATUS register
      axi_drv.read(axi_tran);

      axi_drv.wait_cycles(1);
      scb.check("t5_status_unchanged", axi_if.cb.rdata[31:3] == 29'h00,
               $sformatf("STATUS register should remain unchanged at 0x00000000, got %h", axi_if.cb.rdata[31:3]));
      scb.check("t5_s_axi_bresp_okay", axi_if.cb.bresp == 2'b00,
               $sformatf("AXI write to STATUS should return OKAY response, got %b", axi_if.cb.bresp));

      scb.test_report("Test 5");

      /*----------------------------------------------------------------------- 
        -- Test 6: AXI write to COEFF_DATA propagates to dsp_coeff_data and
        --     generates a one-cycle dsp_coeff_we pulse
        -- DSP must be disabled (CTRL.ENABLE=0) for coeff_write_strobe to fire.
      -----------------------------------------------------------------------*/
/*    
      scb.init_test("Test 6: COEFF_DATA write propagates to dsp_coeff_data and generates dsp_coeff_we pulse");

      // Ensure DSP is disabled
      axi_tran = new(axi_tran.WRITE, ADDR_CTRL, 32'h00);
      axi_drv.write(axi_tran);

      // Write coefficient data
      axi_tran = new(axi_tran.WRITE, ADDR_COEFF_DATA, 32'h00001234);
      axi_drv.write(axi_tran);

      //@(dsp_if.cb);
      scb.check("t6_dsp_coeff_data", dsp_if.cb.dsp_coeff_data[15:0] == 16'h1234,
               $sformatf("dsp_coeff_data[15:0] should be 0x1234, got %h", dsp_if.cb.dsp_coeff_data[15:0]));
      scb.check("t6_dsp_coeff_we", dsp_if.cb.dsp_coeff_we == 1,
               $sformatf("dsp_coeff_we should be 1 during LOAD_COEFF state"));

      // One cycle later: dsp_coeff_we must deassert
      @(dsp_if.cb);
      scb.check("t6_dsp_coeff_we_deassert", dsp_if.cb.dsp_coeff_we == 0,
               $sformatf("dsp_coeff_we should be 0 after LOAD_COEFF completes"));

      scb.test_report("Test 6");

      /*----------------------------------------------------------------------- 
        -- Test 7: AXI write to COEFF_ADDR propagates to dsp_coeff_addr and
        --     also generates a one-cycle dsp_coeff_we pulse
      -----------------------------------------------------------------------*/
/*   
      scb.init_test("Test 7: COEFF_ADDR write propagates to dsp_coeff_addr and generates dsp_coeff_we pulse");

      axi_tran = new(axi_tran.WRITE, ADDR_COEFF_ADDR, 32'h0F);
      axi_drv.write(axi_tran);

      @(dsp_if.cb);
      scb.check("t7_dsp_coeff_addr", dsp_if.cb.dsp_coeff_addr == 8'h0F,
               $sformatf("dsp_coeff_addr should be 0x0F, got %h", dsp_if.cb.dsp_coeff_addr));
      scb.check("t7_dsp_coeff_we", dsp_if.cb.dsp_coeff_we == 1,
               $sformatf("dsp_coeff_we should be 1 during LOAD_COEFF state", dsp_if.cb.dsp_coeff_we));

      @(dsp_if.cb);
      scb.check("t7_dsp_coeff_we_deassert", dsp_if.cb.dsp_coeff_we == 0,
               $sformatf("dsp_coeff_we should be 0 after one cycle"));

      scb.test_report("Test 7");

      /*----------------------------------------------------------------------- 
        -- Test 8: AXI write to DATA_IN triggers DSP SEND handshake
        -- When CTRL.ENABLE=1 and DATA_IN is written, dsp_data_in_valid must
        -- be asserted and the correct sample must appear on dsp_data_in.
        -- FSM must hold dsp_data_in_valid until dsp_data_in_ready is seen.
      -----------------------------------------------------------------------*/
      scb.init_test("Test 8: DATA_IN write triggers DSP SEND handshake");

      // Enable DSP
      axi_tran = new(axi_tran.WRITE, ADDR_CTRL, 32'h01);
      axi_drv.write(axi_tran);

      // Write a sample to DATA_IN
      axi_tran = new(axi_tran.WRITE, ADDR_DATA_IN, 32'h0000BEEF);
      axi_drv.write(axi_tran);

      // After the write completes and the FSM has entered SEND, check outputs
      @(dsp_if.cb);
      scb.check("t8_dsp_data_in_valid", dsp_if.cb.dsp_data_in_valid == 1,
               $sformatf("dsp_data_in_valid should be 1 in SEND state"));
      scb.check("t8_dsp_data_in", dsp_if.cb.dsp_data_in[15:0] == 16'hBEEF,
               $sformatf("dsp_data_in[15:0] should be 0xBEEF"));

      // Simulate DSP accepting data after a couple of cycles
      @(dsp_if.cb);
      scb.check("t8_dsp_data_in_valid_hold", dsp_if.cb.dsp_data_in_valid == 1,
               $sformatf("dsp_data_in_valid must remain 1 while waiting for ready"));

      // DSP asserts ready
      dsp_if.cb.dsp_data_in_ready <= 1;
      @(dsp_if.cb);
      dsp_if.cb.dsp_data_in_ready <= 0;

      scb.check("t8_dsp_data_in_valid_deassert", dsp_if.cb.dsp_data_in_valid == 0,
               $sformatf("dsp_data_in_valid should be 0 after handshake"));

      scb.test_report("Test 8");

      /*----------------------------------------------------------------------- 
        -- Test 9: DSP result captured in DATA_OUT register and readable via AXI
        -- After the DSP asserts dsp_data_out_valid, the result must be stored
        -- in DATA_OUT, dsp_data_out_ready must pulse for exactly one cycle,
        -- and the value must be readable through AXI at address 0x14.
      -----------------------------------------------------------------------*/
      scb.init_test("Test 9: DSP result captured in DATA_OUT register and readable via AXI");

      // DSP is currently in WAIT_RESULT; deliver a result
      dsp_if.cb.dsp_data_out <= 32'h00001234;
      dsp_if.cb.dsp_data_out_valid <= 1;

      repeat(2) @(dsp_if.cb); // Wait a couple of cycles to ensure stable sampling of dsp_data_out_valid:
                              // As dsp_data_out_valid is asserted one clock cycle after dsp_data_out_valid
                              // assertion, if we sample immediately on the next cycle, we might catch the
                              // value before it is set to 1 because we are sampling in the prepone region 
                              // (1 step before the clock edge). By waiting for 2 cycles, we ensure that 
                              // we are sampling after the value has been set to 1.
               
      // dsp_data_out_ready must be pulsed for exactly one cycle
      scb.check("t9_dsp_data_out_valid", dsp_if.cb.dsp_data_out_valid == 1,
               $sformatf("dsp_data_out_valid should be 1 when DSP result is ready"));
      scb.check("t9_dsp_data_out_ready", dsp_if.cb.dsp_data_out_ready == 1,
               $sformatf("dsp_data_out_ready should be 1 on result capture cycle"));

      @(dsp_if.cb);
      scb.check("t9_dsp_data_out_ready_deassert", dsp_if.cb.dsp_data_out_ready == 0,
               $sformatf("dsp_data_out_ready should be 0 one cycle after capture"));


      dsp_if.cb.dsp_data_out_valid <= 0;


      // Read DATA_OUT via AXI
      axi_tran = new(axi_tran.READ, ADDR_DATA_OUT);
      axi_drv.read(axi_tran);
      
      axi_drv.wait_cycles(1);
      scb.check("t9_rdata", axi_if.cb.rdata[15:0] == 16'h1234,
               $sformatf("DATA_OUT readback should be 0x1234 via AXI"));
      scb.check("t9_rresp", axi_if.cb.rresp == 2'b00,
               $sformatf("RRESP should be OKAY for DATA_OUT read"));

      // Disable DSP before next tests
      axi_tran = new(axi_tran.WRITE, ADDR_CTRL, 32'h00);
      axi_drv.write(axi_tran);
      @(dsp_if.cb); @(dsp_if.cb);

      scb.test_report("Test 9");

      /*----------------------------------------------------------------------- 
        -- Test 10: Full write-then-read round trip for COEFF_DATA
        -- Verifies the complete AXI write --> register bank --> AXI read path
        -- for a coefficient value, confirming data integrity end-to-end.
      -----------------------------------------------------------------------*/
      scb.init_test("Test 10: Full write/read round trip for COEFF_DATA");

      axi_tran = new(axi_tran.WRITE, ADDR_COEFF_DATA, 32'h0000ABCD);
      axi_drv.write(axi_tran);
      axi_tran = new(axi_tran.READ, ADDR_COEFF_DATA);
      axi_drv.read(axi_tran);

      axi_drv.wait_cycles(1);
      scb.check("t10_rdata", axi_if.cb.rdata[15:0] == 16'hABCD,
               $sformatf("COEFF_DATA readback should be 0xABCD"));
      scb.check("t10_rdata", axi_if.cb.rdata[15:0] == 16'hABCD,
               $sformatf("COEFF_DATA readback should be 0xABCD"));
      scb.check("t10_reserved", axi_if.cb.rdata[31:16] == 16'h0000,
               $sformatf("COEFF_DATA reserved bits [31:16] must be zero"));
      scb.check("t10_rresp", axi_if.cb.rresp == 2'b00,
               $sformatf("RRESP should be OKAY for COEFF_DATA read"));

      scb.test_report("Test 10");

      /*----------------------------------------------------------------------- 
        -- Test 11: AXI write response BRESP = OKAY for a valid address
        -- A write to any valid, word-aligned address must complete with
        -- BRESP = "00" (OKAY).
      -----------------------------------------------------------------------*/
      scb.init_test("Test 11: Verifying BRESP=OKAY for valid AXI write");

      axi_tran = new(axi_tran.WRITE, ADDR_CTRL, 32'h00);
      axi_drv.write(axi_tran);

      axi_drv.wait_cycles(1);
      scb.check("t11_bresp", axi_if.cb.bresp == 2'b00,
               $sformatf("BRESP should be OKAY (00) for write to valid address"));

      scb.test_report("Test 11");

      /*----------------------------------------------------------------------- 
        -- Test 12: AXI write response BRESP = SLVERR for out-of-range address
        -- A write to an address outside the register map must return
        -- BRESP = "10" (SLVERR).
      -----------------------------------------------------------------------*/
      scb.init_test("Test 12: Verifying BRESP=SLVERR for out-of-range AXI write");

      axi_tran = new(axi_tran.WRITE, ADDR_OOB, 32'hDEADBEEF);
      axi_drv.write(axi_tran);

      axi_drv.wait_cycles(1);
      scb.check("t12_bresp", axi_if.cb.bresp == 2'b10,
               $sformatf("BRESP should be SLVERR (10) for out-of-range write"));

      scb.test_report("Test 12");

      /*----------------------------------------------------------------------- 
        -- Test 13: AXI read response RRESP = SLVERR for out-of-range address
        -- A read from an address outside the register map must return
        -- RRESP = "10" (SLVERR) and RDATA = 0x00000000.
      -----------------------------------------------------------------------*/
      scb.init_test("Test 13: Verifying RRESP=SLVERR for out-of-range AXI read");

      axi_tran = new(axi_tran.READ, ADDR_OOB);
      axi_drv.read(axi_tran);

      axi_drv.wait_cycles(1);
      scb.check("t13_rresp", axi_if.cb.rresp == 2'b10,
               $sformatf("RRESP should be SLVERR (10) for out-of-range read"));
      scb.check("t13_rdata", axi_if.cb.rdata == 32'h00000000,
               $sformatf("RDATA should be 0x00000000 for out-of-range read"));

      scb.test_report("Test 13");

      /*----------------------------------------------------------------------- 
        -- Test 14: STATUS.BUSY held across multiple cycles in WAIT_RESULT
        -- After sending a sample (DATA_IN write with ENABLE=1) and completing
        -- the dsp_data_in handshake, the FSM must remain in WAIT_RESULT with
        -- STATUS.BUSY asserted for multiple cycles until dsp_data_out_valid.
      -----------------------------------------------------------------------*/
      scb.init_test("Test 14: STATUS.BUSY held in WAIT_RESULT until result arrives");

      // Enable DSP and send a sample
      axi_tran = new(axi_tran.WRITE, ADDR_CTRL, 32'h01);
      axi_drv.write(axi_tran);
      axi_tran = new(axi_tran.WRITE, ADDR_DATA_IN, 32'h00005A5A);
      axi_drv.write(axi_tran);

      // Complete the data-in handshake immediately
      @(dsp_if.cb);
      dsp_if.cb.dsp_data_in_ready <= 1;
      @(dsp_if.cb);
      dsp_if.cb.dsp_data_in_ready <= 0;

      // FSM is now in WAIT_RESULT; read STATUS over 4 consecutive cycles
      for (int cycle = 1; cycle <= 4; cycle++) begin
         axi_tran = new(axi_tran.READ, ADDR_STATUS);
         axi_drv.read(axi_tran);
      
         axi_drv.wait_cycles(1);
         scb.check("t14_busy", axi_if.cb.rdata[2] == 1,
                  $sformatf("STATUS.BUSY (bit2) should be 1 in WAIT_RESULT, cycle %0d", cycle));
         scb.check("t14_ready", axi_if.cb.rdata[0] == 0,
                  $sformatf("STATUS.READY (bit0) should be 0 while busy, cycle %0d", cycle));
      end

      // Deliver result to exit WAIT_RESULT
      dsp_if.cb.dsp_data_out <= 32'h00005A5A;
      dsp_if.cb.dsp_data_out_valid <= 1;
      @(dsp_if.cb);
      dsp_if.cb.dsp_data_out_valid <= 0;
      @(dsp_if.cb); @(dsp_if.cb);

      // STATUS should now show ready
      axi_tran = new(axi_tran.READ, ADDR_STATUS);
      axi_drv.read(axi_tran);
   
      axi_drv.wait_cycles(1);
      scb.check("t14_busy_clear", axi_if.cb.rdata[2] == 0,
               $sformatf("STATUS.BUSY should be 0 after result captured"));
      scb.check("t14_ready_set", axi_if.cb.rdata[0] == 1,
               $sformatf("STATUS.READY should be 1 after result captured"));

      scb.general_report();

   #100 $stop; // Stop simulation after some time ("finish" would close ModelSim)
   end 

endmodule