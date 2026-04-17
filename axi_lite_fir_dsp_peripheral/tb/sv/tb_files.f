# ============================================================
# Filelist for AXI Lite FIR DSP Peripheral Testbench
# ============================================================

# Compiler flags
+incdir+.                
+incdir+./interfaces
+incdir+./classes

# Macros / defines
tb/sv/tb_utils.svh

# Interfaces (no dependencies)
tb/sv/interfaces/axi_lite_if.sv
tb/sv/interfaces/external_dsp_if.sv

# Classes (depend on interfaces)
tb/sv/classes/axi_transaction.sv
tb/sv/classes/axi_driver.sv
tb/sv/classes/scoreboard.sv

# Top level testbench (depends on everything)
tb/sv/top_level_wrapper_tb.sv