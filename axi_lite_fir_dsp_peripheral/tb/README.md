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