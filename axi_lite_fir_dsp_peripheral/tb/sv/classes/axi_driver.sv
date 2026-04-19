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

  // Sampling functions to allow other classes to check the state of AXI signals 
  // without needing direct access to the interface.
  function logic sample_bvalid();  return vif.cb.bvalid;  endfunction
  function logic sample_arready(); return vif.cb.arready; endfunction
  function logic sample_rvalid();  return vif.cb.rvalid;  endfunction

  task init();
    @(vif.cb);
    vif.cb.awvalid <= 0;
    vif.cb.wvalid  <= 0;
    vif.cb.bready  <= 0;
    vif.cb.arvalid <= 0;
    vif.cb.rready  <= 0;
    vif.cb.awaddr  <= 0;
    vif.cb.wdata  <= 0;
    vif.cb.araddr  <= 0;
    vif.cb.wstrb   <= 0;
  endtask

  // Note: classes are always passed by reference, so the transaction object 't' 
  // is modified in place to capture the read data and response.
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
  
  // Note: classes are always passed by reference, so the transaction object 't' 
  // is modified in place to capture the read data and response.
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
  
  // Task to wait for a specified number of clock cycles, useful for timing control in test sequences.
  // Like this, this class is the only one that has access to the axi_lite_if.TB  interface,
  // so it can provide utility functions that other classes can call without needing direct access
  // to the interface signals.
  task wait_cycles(int n);
    repeat(n) @(vif.cb);
  endtask
endclass