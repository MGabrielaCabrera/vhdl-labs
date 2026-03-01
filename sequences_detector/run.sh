#!/bin/bash
set -e

mkdir -p build waves

echo "Analyzing design files"
ghdl -a -fsynopsys --workdir=build *.vhd

echo "Elaborating config_fsm testbench"
ghdl -e -fsynopsys --workdir=build -o build/config_fsm sequences_detector_tb

echo "Running config_fsm testbench. Waveforms saved to waves/waves_config_fsm.fst"
build/config_fsm.exe --fst=waves/waves_config_fsm.fst

echo "Opening waveform viewer (only is the fst file exists)"
[ -f waves/waves_config_fsm.fst ] && gtkwave waves/waves_config_fsm.fst &

echo "Test complete! "
