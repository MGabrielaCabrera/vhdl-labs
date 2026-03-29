// Top testbench for AXI Lite Slave Interface
`timescale 1ns/1ps
module top_level_wrapper_tb;

    // Clock and reset generation
   bit clk, rst_n;
   always #5 clk = ~clk; // 100 MHz clock

   // Instantiate the AXI Lite interface
   axi_lite_if axi_if(clk, rst_n);

   // Instantiate the external DSP interface
   external_dsp_if dsp_if(clk, rst_n);

   // Instantiate the testbench program
   test axi_tb(axi_if.TB, dsp_if.TB, clk, rst_n);

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
   endclocking

   // MODPORTS for driving and sampling signals
   // TB modport not really needed because the clocking block is used, but included for clarity
    modport TB (
        input awready, wready, bvalid, arready, rvalid,
        output awaddr, awvalid, wdata, wvalid, wstrb, bready,
                 araddr, arvalid, rready
    );

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
   endclocking

      modport DSP (
         output dsp_data_in, dsp_enable, dsp_reset, dsp_mode, dsp_data_in_valid,
               dsp_data_out_ready, dsp_coeff_data, dsp_coeff_addr, dsp_coeff_we,
         input dsp_data_out, dsp_data_in_ready, dsp_data_out_valid
      );
      modport TB (
         input dsp_data_out, dsp_data_in_ready, dsp_data_out_valid,
         output dsp_data_in, dsp_enable, dsp_reset, dsp_mode, dsp_data_in_valid,
               dsp_data_out_ready, dsp_coeff_data, dsp_coeff_addr, dsp_coeff_we
      );
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
module automatic test(axi_lite_if.TB axi_if, external_dsp_if.TB dsp_if, input logic clk, input logic rst_n);
   // Testbench variables and tasks would be defined here

    // Example: Task to perform a write transaction

/*    initial begin
      rst_n = 0;
      #20 rst_n = 1; // Release reset after 20 ns
   end */

   // Instantiate the AXI Lite Slave Interface

   // Testbench logic to drive the interface and check responses would go here

endmodule