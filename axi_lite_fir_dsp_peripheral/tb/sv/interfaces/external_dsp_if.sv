// External DSP Interface definition for testbench and DUT

interface external_dsp_if(input logic clk, input logic rst_n);
   // Define signals for the external DSP interface
   logic [31:0] dsp_data_in;
   logic [31:0] dsp_data_out;
   logic dsp_enable, dsp_reset;
   logic [1:0] dsp_mode;
   logic dsp_data_in_valid;
   logic dsp_data_in_ready;
   logic dsp_data_out_valid;
   logic dsp_data_out_ready;
   logic [31:0] dsp_coeff_data;
   logic [7:0] dsp_coeff_addr;
   logic dsp_coeff_we;

   // Clocking block for the DSP interface
   clocking cb @(posedge clk);
      default input #1step output; // Sample inputs 1 step before the clock edge, 
                                   // drive outputs in the current clock edge
         output dsp_data_out, dsp_data_in_ready, dsp_data_out_valid;
         input dsp_data_in, dsp_enable, dsp_reset, dsp_mode, dsp_data_in_valid,
               dsp_data_out_ready, dsp_coeff_data, dsp_coeff_addr, dsp_coeff_we;
   endclocking

   modport DSP (
      output dsp_data_in, dsp_enable, dsp_reset, dsp_mode, dsp_data_in_valid,
            dsp_data_out_ready, dsp_coeff_data, dsp_coeff_addr, dsp_coeff_we,
      input dsp_data_out, dsp_data_in_ready, dsp_data_out_valid
   );
   modport TB (clocking cb);
   modport MONITOR (
      input dsp_data_in, dsp_enable, dsp_reset, dsp_mode, dsp_data_in_valid,
            dsp_data_out_ready, dsp_coeff_data, dsp_coeff_addr, dsp_coeff_we,
            dsp_data_out, dsp_data_in_ready, dsp_data_out_valid
   );
endinterface