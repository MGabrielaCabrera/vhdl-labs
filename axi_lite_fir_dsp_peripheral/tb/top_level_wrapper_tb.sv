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

   //TODO: monitor


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
      default input #1step output;
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
      $display("DSP interface reflects CTRL settings correctly");

      read_transaction(ADDR_CTRL); // Read back CTRL register
      // Sample rdata for checking
      @(axi_if.cb);
      t2_rdata: assert (axi_if.cb.rdata == 32'h0B) 
         else $error("Readback data mismatch: expected 0x0B, got %h", axi_if.cb.rdata);

      $display("Readback from CTRL register is correct");
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
    
    
    #100 $stop; // Stop simulation after some time ("finish" would close ModelSim)
   end 

   // Instantiate the AXI Lite Slave Interface

   // Testbench logic to drive the interface and check responses would go here

endmodule