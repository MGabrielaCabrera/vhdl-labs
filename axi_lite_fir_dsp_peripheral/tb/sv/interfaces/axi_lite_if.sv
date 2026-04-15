// AXI Lite Interface definition for testbench and DUT

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