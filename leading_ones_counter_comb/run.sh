#!/bin/bash
set -e

mkdir -p build waves

echo "Analyzing design files"
ghdl -a -fsynopsys --workdir=build *.vhd

echo "Elaborating testbench"
ghdl -e -fsynopsys --workdir=build -o build/config_rtl config_rtl

echo "Running testbench. Waveforms saved to waves/waves.fst"
build/config_rtl.exe --fst=waves/waves.fst

echo "Opening waveform viewer (only is the fst file exists)"
[ -f waves/waves.fst ] && gtkwave waves/waves.fst &

echo "Test complete! "
