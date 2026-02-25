#!/bin/bash
set -e

mkdir -p build waves

echo "Analyzing package files"
ghdl -a -fsynopsys --workdir=build *_pkg.vhd

echo "Analyzing design files"
ghdl -a -fsynopsys --workdir=build fir_filter.vhd
ghdl -a -fsynopsys --workdir=build fir_filter_tb.vhd

echo "Elaborating chain_arranged_adders testbench"
ghdl -e -fsynopsys --workdir=build -o build/config_rtl_chain_arranged_adders config_rtl_chain_arranged_adders

echo "Running config_rtl_chain_arranged_adders testbench. Waveforms saved to waves/waves_config_rtl_chain_arranged_adders.fst"
build/config_rtl_chain_arranged_adders.exe --fst=waves/waves_config_rtl_chain_arranged_adders.fst

echo "Opening waveform viewer (only is the fst file exists)"
[ -f waves/waves_config_rtl_chain_arranged_adders.fst ] && gtkwave waves/waves_config_rtl_chain_arranged_adders.fst &

echo "Elaborating pipeline_arranged_adders testbench"
ghdl -e -fsynopsys --workdir=build -o build/config_rtl_pipeline_arranged_adders config_rtl_pipeline_arranged_adders

echo "Running config_rtl_pipeline_arranged_adders testbench. Waveforms saved to waves/waves_config_rtl_pipeline_arranged_adders.fst"
build/config_rtl_pipeline_arranged_adders.exe --fst=waves/waves_config_rtl_pipeline_arranged_adders.fst

echo "Opening waveform viewer for config_rtl_pipeline_arranged_adders (only if the fst file exists)"
[ -f waves/waves_config_rtl_pipeline_arranged_adders.fst ] && gtkwave waves/waves_config_rtl_pipeline_arranged_adders.fst &


echo "Test complete! "
