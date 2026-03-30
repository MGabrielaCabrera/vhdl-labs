# Exit on error
onerror {stop}

# Create work library
vlib work
vmap work work

echo "Compiling VHDL design files"
vcom -2008 axi_lite_slave_if.vhd
vcom -2008 control_fsm.vhd
vcom -2008 register_bank.vhd
vcom -2008 top_level_wrapper.vhd

echo "Compiling SystemVerilog testbench"
vlog tb/top_level_wrapper_tb.sv

echo "Starting simulation"

# IMPORTANT: use the actual name of your testbench module
vsim work.top_level_wrapper_tb

# Add all signals to waveform window
add wave -r *

# Run simulation until completion
run -all

echo "Simulation complete!"

# Optional: quit automatically
# quit -f

pause