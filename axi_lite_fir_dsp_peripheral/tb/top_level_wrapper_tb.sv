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

interface axi_lite_if(input logic clk, input logic rst_n);
   logic [31:0] awaddr;
   logic awvalid, awready;
   logic [31:0] wdata;
   logic wvalid, wready;
   logic [3:0] wstrb;
   logic bvalid, bready;
   logic [31:0] araddr;
   logic arvalid, arready;
   logic rvalid, rready;
   logic [31:0] rdata;
   logic [1:0] rresp;
   logic [1:0] bresp;

   clocking cb @(posedge clk);
      default input #1step output;
         input awready, wready, bvalid, arready, rvalid,
               rdata, rresp, bresp;
         output awaddr, awvalid, wdata, wvalid, wstrb, bready,
               araddr, arvalid, rready;
   endclocking

   // MODPORTS for driving and sampling signals
   // TB modport not really needed because the clocking block is used, but included for clarity
    modport TB (clocking cb);

    modport DUT (
        input awaddr, awvalid, wdata, wvalid, wstrb, bready,
            araddr, arvalid, rready,
        output awready, wready, bvalid, arready, rvalid,
            rdata, rresp, bresp
    );

    modport MONITOR (
        input awaddr, awvalid, wdata, wvalid, wstrb, bready,
            araddr, arvalid, rready, awready, wready, bvalid, 
            arready, rvalid, rdata, rresp, bresp
    );

endinterface

interface external_dsp_if(input logic clk, input logic rst_n);
   // Define signals for the external DSP interface
   logic [31:0] dsp_data_in;
   logic [31:0] dsp_data_out;
   logic dsp_enable, dsp_reset;
   logic [1:0] dsp_mode;
   logic dsp_data_in_valid;
   logic dsp_data_in_ready;
   logic dsp_data_out_valid;
   logic dsp_data_out_ready;
   logic [31:0] dsp_coeff_data;
   logic [7:0] dsp_coeff_addr;
   logic dsp_coeff_we;

   // Clocking block for the DSP interface
   clocking cb @(posedge clk);
      default input #1step output; // Sample inputs 1 step before the clock edge, 
                                   // drive outputs in the current clock edge
         output dsp_data_out, dsp_data_in_ready, dsp_data_out_valid;
         input dsp_data_in, dsp_enable, dsp_reset, dsp_mode, dsp_data_in_valid,
               dsp_data_out_ready, dsp_coeff_data, dsp_coeff_addr, dsp_coeff_we;
   endclocking

   modport DSP (
      output dsp_data_in, dsp_enable, dsp_reset, dsp_mode, dsp_data_in_valid,
            dsp_data_out_ready, dsp_coeff_data, dsp_coeff_addr, dsp_coeff_we,
      input dsp_data_out, dsp_data_in_ready, dsp_data_out_valid
   );
   modport TB (clocking cb);
   modport MONITOR (
      input dsp_data_in, dsp_enable, dsp_reset, dsp_mode, dsp_data_in_valid,
            dsp_data_out_ready, dsp_coeff_data, dsp_coeff_addr, dsp_coeff_we,
            dsp_data_out, dsp_data_in_ready, dsp_data_out_valid
   );
endinterface

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

   // Task to perform a write transaction
   task write_transaction(input logic [31:0] addr, input logic [31:0] data, input logic [3:0] strb = 4'b1111);
        @(axi_if.cb);
        axi_if.cb.awaddr <= addr;
        axi_if.cb.awvalid <= 1;
        axi_if.cb.wdata <= data;
        axi_if.cb.wvalid <= 1;
        axi_if.cb.wstrb <= strb;
        wait (axi_if.cb.awready && axi_if.cb.wready);
        @(axi_if.cb);
        axi_if.cb.awvalid <= 0;
        axi_if.cb.wvalid <= 0;
        wait (axi_if.cb.bvalid);
        @(axi_if.cb);
        axi_if.cb.bready <= 1;
        @(axi_if.cb);
        axi_if.cb.bready <= 0;
    endtask
    
    // Task to perform a read transaction
   task read_transaction(input logic [31:0] addr);
         @(axi_if.cb);
         axi_if.cb.araddr <= addr;
         axi_if.cb.arvalid <= 1;
         wait (axi_if.cb.arready);
         @(axi_if.cb);
         axi_if.cb.arvalid <= 0;
         wait (axi_if.cb.rvalid);
         @(axi_if.cb);
         // Sample rdata and rresp here for checking
         axi_if.cb.rready <= 1;
         @(axi_if.cb);
         axi_if.cb.rready <= 0;
   endtask


   initial begin
      // Signal initialization
      @(posedge axi_if.cb);
         axi_if.cb.awaddr <= 0;
         axi_if.cb.awvalid <= 0;
         axi_if.cb.wdata <= 0;
         axi_if.cb.wvalid <= 0;
         axi_if.cb.wstrb <= 0;
         axi_if.cb.bready <= 0;
         axi_if.cb.araddr <= 0;
         axi_if.cb.arvalid <= 0;
         axi_if.cb.rready <= 0;
   
         dsp_if.cb.dsp_data_in_ready <= 0;
         dsp_if.cb.dsp_data_out_valid <= 0;
         dsp_if.cb.dsp_data_out <= 0;
   
      /*---------------------------------------------------------------
        -- Test 1: Reset state
        -- All AXI output signals must be at their safe defaults while
        -- rst_n is held low.
        ---------------------------------------------------------------*/
      $display("Test 1: Verifying AXI output reset state");

      @(posedge axi_if.cb);
      t1_bvalid: assert (axi_if.cb.bvalid == 0) 
         else $error("bvalid should be 0 after reset");
      t1_arready: assert (axi_if.cb.arready == 0) 
         else $error("arready should be 0 after reset");
      t1_rvalid: assert (axi_if.cb.rvalid == 0) 
         else $error("rvalid should be 0 after reset");
      t1_dsp_enable: assert (dsp_if.cb.dsp_enable == 0) 
         else $error("DSP enable should be 0 after reset");
      t1_dsp_reset: assert (dsp_if.cb.dsp_reset == 0) 
         else $error("DSP reset should be 0 after reset");
      t1_dsp_data_in_valid: assert (dsp_if.cb.dsp_data_in_valid == 0) 
         else $error("DSP data_in_valid should be 0 after reset");
      t1_dsp_data_out_ready: assert (dsp_if.cb.dsp_data_out_ready == 0) 
         else $error("DSP data_out_ready should be 0 after reset");
      t1_dsp_coeff_we: assert (dsp_if.cb.dsp_coeff_we == 0) 
         else $error("DSP coeff_we should be 0 after reset");
      $display("Test 1 passed: AXI outputs and DSP control signals are in reset state");

      /*-----------------------------------------------------------------------
        -- Test 2: AXI write to CTRL and readback
        -- Writing enable=1, reset=1, mode="10" via AXI must reach the DSP
        -- outputs and be readable back at address 0x00.
        -- CTRL encoding: bit0=enable, bit1=reset, bit3:2=mode --> 0x0B
      -----------------------------------------------------------------------*/
      $display("Test 2: AXI write to CTRL and readback");

      write_transaction(ADDR_CTRL, 32'h0B); // Write to CTRL register
      // Wait for the DSP interface to reflect the changes
      @(posedge dsp_if.cb);
      t2_dsp_enable: assert (dsp_if.cb.dsp_enable == 1) 
         else $error("DSP enable should be 1 after writing to CTRL");
      t2_dsp_reset: assert (dsp_if.cb.dsp_reset == 1) 
         else $error("DSP reset should be 1 after writing to CTRL");
      t2_dsp_mode: assert (dsp_if.cb.dsp_mode == 2) 
         else $error("DSP mode should be 2 after writing to CTRL");

      read_transaction(ADDR_CTRL); // Read back CTRL register
      // Sample rdata for checking
      @(axi_if.cb);
      t2_rdata: assert (axi_if.cb.rdata == 32'h0B) 
         else $error("Readback data mismatch: expected 0x0B, got %h", axi_if.cb.rdata);

      $display("Test 2 passed: AXI write to CTRL and readback verified");
    
      /*-----------------------------------------------------------------------
        -- Test 3: CTRL reserved bits are forced to zero
        -- Writing 0xFFFFFFFF to CTRL must only store bits [3:0]; all upper
        -- bits must read back as zero through the full AXI path.
      -----------------------------------------------------------------------*/
      $display("Test 3: CTRL reserved bits are forced to zero");

      write_transaction(ADDR_CTRL, 32'hFFFFFFFF); // Write to CTRL register
      read_transaction(ADDR_CTRL); // Read back CTRL register

      // Sample rdata for checking
      @(axi_if.cb);
      t3_rdata_reserved_bits: assert (axi_if.cb.rdata[31:4] == 28'h00) 
         else $error("CTRL reserved bits [31:4] must read as zero, got %h", axi_if.cb.rdata[31:4]);
      t3_rdata: assert (axi_if.cb.rdata[3:0] == 4'hF) 
         else $error("CTRL writable bits [3:0] should all be '1', got %h", axi_if.cb.rdata[3:0]);
      
      // Restore
      write_transaction(ADDR_CTRL, 32'h00); // Write to CTRL register

      $display("Test 3 passed:  CTRL reserved bits are forced to zero verified");

      /*-----------------------------------------------------------------------
        -- Test 4: AXI write to CTRL enables DSP (dsp_enable propagation)
        -- Verifies that writing bit 0 of CTRL makes dsp_enable go high, and
        -- clearing it makes it go low again.
      -----------------------------------------------------------------------*/
      $display("Test 4: Verifying CTRL enable bit propagates to dsp_enable");

      write_transaction(ADDR_CTRL, 32'h01); // Set enable bit
      @(posedge dsp_if.cb);
      t4_dsp_enable_set: assert (dsp_if.cb.dsp_enable == 1) 
         else $error("DSP enable should be 1 after setting enable bit in CTRL");
      t4_dsp_reset_unchanged: assert (dsp_if.cb.dsp_reset == 0) 
         else $error("DSP reset should remain 0 after setting enable bit in CTRL");
      t4_dsp_mode_unchanged: assert (dsp_if.cb.dsp_mode == 0) 
         else $error("DSP mode should remain 0 after setting enable bit in CTRL");
      
      write_transaction(ADDR_CTRL, 32'h00); // Clear enable bit
      @(posedge dsp_if.cb);
      t4_dsp_enable_clear: assert (dsp_if.cb.dsp_enable == 0) 
         else $error("DSP enable should be 0 after clearing enable bit in CTRL"); 

      /*-----------------------------------------------------------------------
        -- T5: AXI write to STATUS is silently ignored (RO register)
        -- STATUS must not change as a result of a software AXI write.
        -- The response must still be OKAY (write accepted by AXI slave).
      -----------------------------------------------------------------------*/
      $display("Test 5: Verifying STATUS is read-only (AXI write ignored)");
   
      write_transaction(ADDR_STATUS, 32'hFFFFFFFF); // Attempt to write to STATUS register
      // Check that STATUS did not change
      read_transaction(ADDR_STATUS); // Read back STATUS register
      @(axi_if.cb);
      t5_status_unchanged: assert (axi_if.cb.rdata[31:3] == 29'h00) 
         else $error("STATUS register should remain unchanged at 0x00000000, got %h", axi_if.cb.rdata[31:3]);
      t5_s_axi_bresp_okay: assert (axi_if.cb.bresp == 2'b00) 
         else $error("AXI write to STATUS should return OKAY response, got %b", axi_if.cb.bresp);

      $display("Test 5 passed: STATUS register is read-only and write is ignored");
    
    
      /*----------------------------------------------------------------------- 
        -- Test 6: AXI write to COEFF_DATA propagates to dsp_coeff_data and
        --     generates a one-cycle dsp_coeff_we pulse
        -- DSP must be disabled (CTRL.ENABLE=0) for coeff_write_strobe to fire.
      -----------------------------------------------------------------------*/
/*       $display("Test 6: Verifying COEFF_DATA write propagates to DSP coefficient interface");

      // Ensure DSP is disabled
      write_transaction(ADDR_CTRL, 32'h00);

      // Write coefficient data
      write_transaction(ADDR_COEFF_DATA, 32'h00001234);

      //@(dsp_if.cb);

      t6_dsp_coeff_data: assert (dsp_if.cb.dsp_coeff_data[15:0] == 16'h1234) 
         else $error("dsp_coeff_data[15:0] should be 0x1234, got %h", dsp_if.cb.dsp_coeff_data[15:0]);
      t6_dsp_coeff_we: assert (dsp_if.cb.dsp_coeff_we == 1) 
         else $error("dsp_coeff_we should be 1 during LOAD_COEFF state");

      // One cycle later: dsp_coeff_we must deassert
      @(dsp_if.cb);
      t6_dsp_coeff_we_deassert: assert (dsp_if.cb.dsp_coeff_we == 0) 
         else $error("dsp_coeff_we should be 0 after LOAD_COEFF completes");

      $display("Test 6 passed: COEFF_DATA write propagates correctly"); */

      /*----------------------------------------------------------------------- 
        -- Test 7: AXI write to COEFF_ADDR propagates to dsp_coeff_addr and
        --     also generates a one-cycle dsp_coeff_we pulse
      -----------------------------------------------------------------------*/
/*       $display("Test 7: Verifying COEFF_ADDR write propagates to dsp_coeff_addr");

      write_transaction(ADDR_COEFF_ADDR, 32'h0F);

      @(dsp_if.cb);
      t7_dsp_coeff_addr: assert (dsp_if.cb.dsp_coeff_addr == 8'h0F) 
         else $error("dsp_coeff_addr should be 0x0F");
      t7_dsp_coeff_we: assert (dsp_if.cb.dsp_coeff_we == 1) 
         else $error("dsp_coeff_we should be 1 during LOAD_COEFF state");

      @(dsp_if.cb);
      t7_dsp_coeff_we_deassert: assert (dsp_if.cb.dsp_coeff_we == 0) 
         else $error("dsp_coeff_we should be 0 after one cycle");

      $display("Test 7 passed: COEFF_ADDR write propagates correctly"); */

      /*----------------------------------------------------------------------- 
        -- Test 8: AXI write to DATA_IN triggers DSP SEND handshake
        -- When CTRL.ENABLE=1 and DATA_IN is written, dsp_data_in_valid must
        -- be asserted and the correct sample must appear on dsp_data_in.
        -- FSM must hold dsp_data_in_valid until dsp_data_in_ready is seen.
      -----------------------------------------------------------------------*/
      $display("Test 8: Verifying DATA_IN write triggers DSP sample send");

      // Enable DSP
      write_transaction(ADDR_CTRL, 32'h01);

      // Write a sample to DATA_IN
      write_transaction(ADDR_DATA_IN, 32'h0000BEEF);

      // After the write completes and the FSM has entered SEND, check outputs
      @(dsp_if.cb);
      t8_dsp_data_in_valid: assert (dsp_if.cb.dsp_data_in_valid == 1) 
         else $error("dsp_data_in_valid should be 1 in SEND state");
      t8_dsp_data_in: assert (dsp_if.cb.dsp_data_in[15:0] == 16'hBEEF) 
         else $error("dsp_data_in[15:0] should be 0xBEEF");

      // Simulate DSP accepting data after a couple of cycles
      @(dsp_if.cb);
      t8_dsp_data_in_valid_hold: assert (dsp_if.cb.dsp_data_in_valid == 1) 
         else $error("dsp_data_in_valid must remain 1 while waiting for ready");

      // DSP asserts ready
      dsp_if.cb.dsp_data_in_ready <= 1;
      @(dsp_if.cb);
      dsp_if.cb.dsp_data_in_ready <= 0;

      t8_dsp_data_in_valid_deassert: assert (dsp_if.cb.dsp_data_in_valid == 0) 
         else $error("dsp_data_in_valid should be 0 after handshake");

      $display("Test 8 passed: DATA_IN write triggers DSP SEND handshake");

      /*----------------------------------------------------------------------- 
        -- Test 9: DSP result captured in DATA_OUT register and readable via AXI
        -- After the DSP asserts dsp_data_out_valid, the result must be stored
        -- in DATA_OUT, dsp_data_out_ready must pulse for exactly one cycle,
        -- and the value must be readable through AXI at address 0x14.
      -----------------------------------------------------------------------*/
      $display("Test 9: Verifying DSP result captured and readable via AXI");


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
      t9_dsp_data_out_ready: assert (dsp_if.cb.dsp_data_out_ready == 1) 
         else $error("dsp_data_out_ready should be 1 on result capture cycle");

      @(dsp_if.cb);
      t9_dsp_data_out_ready_deassert: assert (dsp_if.cb.dsp_data_out_ready == 0) 
         else $error("dsp_data_out_ready should be 0 one cycle after capture");


      dsp_if.cb.dsp_data_out_valid <= 0;


      // Read DATA_OUT via AXI
      read_transaction(ADDR_DATA_OUT);
      @(axi_if.cb);
      t9_rdata: assert (axi_if.cb.rdata[15:0] == 16'h1234) 
         else $error("DATA_OUT readback should be 0x1234 via AXI");
      t9_rresp: assert (axi_if.cb.rresp == 2'b00) 
         else $error("RRESP should be OKAY for DATA_OUT read");

      // Disable DSP before next tests
      write_transaction(ADDR_CTRL, 32'h00);
      @(dsp_if.cb); @(dsp_if.cb);

      $display("Test 9 passed: DSP result captured and readable via AXI");

      /*----------------------------------------------------------------------- 
        -- Test 10: Full write-then-read round trip for COEFF_DATA
        -- Verifies the complete AXI write --> register bank --> AXI read path
        -- for a coefficient value, confirming data integrity end-to-end.
      -----------------------------------------------------------------------*/
      $display("Test 10: Verifying full write/read round trip for COEFF_DATA");

      write_transaction(ADDR_COEFF_DATA, 32'h0000ABCD);
      read_transaction(ADDR_COEFF_DATA);
      @(axi_if.cb);
      t10_rdata: assert (axi_if.cb.rdata[15:0] == 16'hABCD) 
         else $error("COEFF_DATA readback should be 0xABCD");
      t10_reserved: assert (axi_if.cb.rdata[31:16] == 16'h0000) 
         else $error("COEFF_DATA reserved bits [31:16] must be zero");
      t10_rresp: assert (axi_if.cb.rresp == 2'b00) 
         else $error("RRESP should be OKAY for COEFF_DATA read");

      $display("Test 10 passed: Full write/read round trip for COEFF_DATA verified");

      /*----------------------------------------------------------------------- 
        -- Test 11: AXI write response BRESP = OKAY for a valid address
        -- A write to any valid, word-aligned address must complete with
        -- BRESP = "00" (OKAY).
      -----------------------------------------------------------------------*/
      $display("Test 11: Verifying BRESP=OKAY for valid AXI write");

      write_transaction(ADDR_CTRL, 32'h00);
      @(axi_if.cb);
      t11_bresp: assert (axi_if.cb.bresp == 2'b00) 
         else $error("BRESP should be OKAY (00) for write to valid address");

      $display("Test 11 passed: BRESP=OKAY for valid AXI write");

      /*----------------------------------------------------------------------- 
        -- Test 12: AXI write response BRESP = SLVERR for out-of-range address
        -- A write to an address outside the register map must return
        -- BRESP = "10" (SLVERR).
      -----------------------------------------------------------------------*/
      $display("Test 12: Verifying BRESP=SLVERR for out-of-range AXI write");

      write_transaction(ADDR_OOB, 32'hDEADBEEF);
      @(axi_if.cb);
      t12_bresp: assert (axi_if.cb.bresp == 2'b10) 
         else $error("BRESP should be SLVERR (10) for out-of-range write");

      $display("Test 12 passed: BRESP=SLVERR for out-of-range AXI write");

      /*----------------------------------------------------------------------- 
        -- Test 13: AXI read response RRESP = SLVERR for out-of-range address
        -- A read from an address outside the register map must return
        -- RRESP = "10" (SLVERR) and RDATA = 0x00000000.
      -----------------------------------------------------------------------*/
      $display("Test 13: Verifying RRESP=SLVERR for out-of-range AXI read");

      read_transaction(ADDR_OOB);
      @(axi_if.cb);
      t13_rresp: assert (axi_if.cb.rresp == 2'b10) 
         else $error("RRESP should be SLVERR (10) for out-of-range read");
      t13_rdata: assert (axi_if.cb.rdata == 32'h00000000) 
         else $error("RDATA should be 0x00000000 for out-of-range read");

      $display("Test 13 passed: RRESP=SLVERR for out-of-range AXI read");

      /*----------------------------------------------------------------------- 
        -- Test 14: STATUS.BUSY held across multiple cycles in WAIT_RESULT
        -- After sending a sample (DATA_IN write with ENABLE=1) and completing
        -- the dsp_data_in handshake, the FSM must remain in WAIT_RESULT with
        -- STATUS.BUSY asserted for multiple cycles until dsp_data_out_valid.
      -----------------------------------------------------------------------*/
      $display("Test 14: Verifying STATUS.BUSY held in WAIT_RESULT until result arrives");

      // Enable DSP and send a sample
      write_transaction(ADDR_CTRL, 32'h01);
      write_transaction(ADDR_DATA_IN, 32'h00005A5A);

      // Complete the data-in handshake immediately
      @(dsp_if.cb);
      dsp_if.cb.dsp_data_in_ready <= 1;
      @(dsp_if.cb);
      dsp_if.cb.dsp_data_in_ready <= 0;

      // FSM is now in WAIT_RESULT; read STATUS over 4 consecutive cycles
      for (int cycle = 1; cycle <= 4; cycle++) begin
         read_transaction(ADDR_STATUS);
         @(axi_if.cb);
         t14_busy: assert (axi_if.cb.rdata[2] == 1) 
            else $error("STATUS.BUSY (bit2) should be 1 in WAIT_RESULT, cycle %0d", cycle);
         t14_ready: assert (axi_if.cb.rdata[0] == 0) 
            else $error("STATUS.READY (bit0) should be 0 while busy, cycle %0d", cycle);
      end

      // Deliver result to exit WAIT_RESULT
      dsp_if.cb.dsp_data_out <= 32'h00005A5A;
      dsp_if.cb.dsp_data_out_valid <= 1;
      @(dsp_if.cb);
      dsp_if.cb.dsp_data_out_valid <= 0;
      @(dsp_if.cb); @(dsp_if.cb);

      // STATUS should now show ready
      read_transaction(ADDR_STATUS);
      @(axi_if.cb);
      t14_busy_clear: assert (axi_if.cb.rdata[2] == 0) 
         else $error("STATUS.BUSY should be 0 after result captured");
      t14_ready_set: assert (axi_if.cb.rdata[0] == 1) 
         else $error("STATUS.READY should be 1 after result captured");

      $display("Test 14 passed: STATUS.BUSY held in WAIT_RESULT until result arrives");
    
    
    #100 $stop; // Stop simulation after some time ("finish" would close ModelSim)
   end 

   // Instantiate the AXI Lite Slave Interface

   // Testbench logic to drive the interface and check responses would go here

endmodule