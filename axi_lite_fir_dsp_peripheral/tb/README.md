## Testbench

### simple_vhdl/
VHDL testbenches — directed tests, written first to validate
basic functionality quickly.

### sv/
SystemVerilog structured testbench — refactored to introduce
interfaces, clocking blocks, and class-based drivers/scoreboards
for better reusability and scalability toward UVM.

Classes follow a two-layer design: `AXI_Transaction` holds the data
describing a transfer, while `AXI_Driver` owns the virtual interface
and handles the bus protocol. This mirrors the UVM driver/sequence_item
pattern, keeping stimulus generation, protocol handling, and result
checking as independent, reusable components.

Ownership of interface signals:

- AXI_Driver: sole owner of the AXI Lite interface. All reads and writes 
to axi_lite_if go through this class. Results are returned via 
AXI_Transaction fields (rdata_out, resp) so the rest of the testbench
 never needs to touch the interface directly.

- Scoreboard: receives AXI_Transaction objects and checks their fields.
 Has no access to any interface.

- test module: orchestrates the test sequence: creates AXI_Transaction
 objects, calls AXI_Driver tasks, and passes results to the Scoreboard.
  Also directly drives and samples the DSP interface (external_dsp_if)
   as no driver class exists yet for that side.

NOTE: The current structure aims to approximate a UVM design. 
Modifications are still needed, as assertions shouldn't be displayed
on the scoreboard or monitor. The goal is to achieve something like this:

```
uvm_sequence       uvm_driver
 (test mod) -->  (AXI_Driver)  -->  DUT
                                     |
                   uvm_monitor    <--+
                       |
                       V mailbox/TLM
                  uvm_scoreboard
```