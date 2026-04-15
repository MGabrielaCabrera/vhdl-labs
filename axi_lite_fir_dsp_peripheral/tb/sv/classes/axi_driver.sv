// AXI_Driver class — protocol-level driver for the AXI Lite bus.
// Takes an AXI_Transaction object and translates it into cycle-accurate
// signal toggles on the virtual interface, handling the full handshake
// sequence for both write (AW+W+B) and read (AR+R) channels.
// Follows the same separation of concerns as UVM's uvm_driver pattern.

`include "../interfaces/axi_lite_if.sv"
`include "axi_transaction.sv"

class AXI_Driver;
  virtual axi_lite_if.TB vif;

  function new(virtual axi_lite_if.TB i);
    vif = i;
  endfunction

  task write(input AXI_Transaction t);
    @(vif.cb);
    vif.cb.awaddr  <= t.addr;
    vif.cb.awvalid <= 1;
    vif.cb.wdata   <= t.data;
    vif.cb.wvalid  <= 1;
    vif.cb.wstrb   <= t.strb;
    wait(vif.cb.awready && vif.cb.wready);
    @(vif.cb);
    vif.cb.awvalid <= 0;
    vif.cb.wvalid  <= 0;
    wait(vif.cb.bvalid);
    @(vif.cb);
    vif.cb.bready <= 1;
    t.resp = vif.cb.bresp;   // captura respuesta
    @(vif.cb);
    vif.cb.bready <= 0;
  endtask

  task read(input AXI_Transaction t);
    @(vif.cb);
    vif.cb.araddr  <= t.addr;
    vif.cb.arvalid <= 1;
    wait(vif.cb.arready);
    @(vif.cb);
    vif.cb.arvalid <= 0;
    wait(vif.cb.rvalid);
    @(vif.cb);
    vif.cb.rready <= 1;
    t.rdata_out = vif.cb.rdata; // captura dato
    t.resp      = vif.cb.rresp;
    @(vif.cb);
    vif.cb.rready <= 0;
  endtask
endclass