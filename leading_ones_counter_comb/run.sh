#!/bin/bash
set -e

mkdir -p build waves

echo "Analyzing design files"
ghdl -a -fsynopsys --workdir=build *.vhd

echo "Elaborating config_rtl testbench"
ghdl -e -fsynopsys --workdir=build -o build/config_rtl config_rtl

echo "Running config_rtl testbench. Waveforms saved to waves/waves_config_rtl.fst"
build/config_rtl.exe --fst=waves/waves_config_rtl.fst

echo "Opening waveform viewer (only is the fst file exists)"
[ -f waves/waves_config_rtl.fst ] && gtkwave waves/waves_config_rtl.fst &

echo "Elaborating config_behavioral testbench"
ghdl -e -fsynopsys --workdir=build -o build/config_behavioral config_behavioral

echo "Running config_behavioral testbench. Waveforms saved to waves/waves_config_behavioral.fst"
build/config_behavioral.exe --fst=waves/waves_config_behavioral.fst

echo "Opening waveform viewer for config_behavioral (only if the fst file exists)"
[ -f waves/waves_config_behavioral.fst ] && gtkwave waves/waves_config_behavioral.fst &

echo "Test complete! "
