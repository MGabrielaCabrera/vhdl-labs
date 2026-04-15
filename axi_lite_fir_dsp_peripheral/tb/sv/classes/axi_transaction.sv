// AXI_Transaction class — data container for a single AXI Lite transfer.
// Holds address, data, strobe, and response fields for both write and read
// transactions. Kept separate from the driver so it can be shared across
// the scoreboard, monitor, and stimulus generator without any dependency
// on the virtual interface.

class AXI_Transaction;
  typedef enum {WRITE, READ} trans_type_e;

  trans_type_e  trans_type;
  logic [31:0]  addr;
  logic [31:0]  data;
  logic [3:0]   strb;
  logic [1:0]   resp;      // capture bresp/rresp
  logic [31:0]  rdata_out; // capture rdata

  function new(trans_type_e t, logic [31:0] a, logic [31:0] d = 0, logic [3:0] s = 4'b1111);
    trans_type = t;
    addr = a; data = d; strb = s;
  endfunction
endclass