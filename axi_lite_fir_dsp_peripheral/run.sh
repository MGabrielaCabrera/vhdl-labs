#!/bin/bash
set -e

mkdir -p build waves

echo "Analyzing design files"
ghdl -a --std=08 -fsynopsys --workdir=build axi_lite_slave_if.vhd
ghdl -a --std=08 -fsynopsys --workdir=build axi_lite_slave_if_tb.vhd
ghdl -a --std=08 -fsynopsys --workdir=build control_fsm.vhd
ghdl -a --std=08 -fsynopsys --workdir=build control_fsm_tb.vhd

echo "Elaborating axi_lite_slave_if testbench"
ghdl -e --std=08 -fsynopsys --workdir=build -o build/axi_lite_slave_if_tb.exe axi_lite_slave_if_tb

echo "Running axi_lite_slave_if_tb testbench. Waveforms saved to waves/waves_axi_lite_slave_if_tb.fst"
build/axi_lite_slave_if_tb.exe --fst=waves/waves_axi_lite_slave_if_tb.fst

echo "Opening waveform viewer (only if the fst file exists)"
[ -f waves/waves_axi_lite_slave_if_tb.fst ] && gtkwave waves/waves_axi_lite_slave_if_tb.fst &  

echo "Elaborating control_fsm testbench"
ghdl -e --std=08 -fsynopsys --workdir=build -o build/control_fsm_tb.exe control_fsm_tb

echo "Running control_fsm_tb testbench. Waveforms saved to waves/waves_control_fsm_tb.fst"
build/control_fsm_tb.exe --fst=waves/waves_control_fsm_tb.fst

echo "Opening waveform viewer (only if the fst file exists)"
[ -f waves/waves_control_fsm_tb.fst ] && gtkwave waves/waves_control_fsm_tb.fst &  



echo "Test complete! "
