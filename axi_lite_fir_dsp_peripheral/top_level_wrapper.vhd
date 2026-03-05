--------------------------------------------------------------------------------
-- Engineer:    Gabriela Cabrera
-- 
-- Design:     Top-Level Wrapper
-- Module:      top_level_wrapper
-- Description: The top-level module defines the external interface of the peripheral 
--              and structurally integrates all internal submodules. It instantiates 
--              the AXI-Lite slave interface, register bank, control finite state machine,
--              DSP interface adapter, and shared package definitions, interconnecting 
--              them through clearly defined signals. This module contains no behavioral
--              logic and serves strictly as a structural hierarchy layer to improve 
--              readability, maintainability, and system integration.
-- Date:        04/03/2026
-- Version:     1.0
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity top_level_wrapper is
    port (
        -- General ports
        clk : in std_logic; -- Clock signal
        rst_n : in std_logic; -- Active low reset

        -- Axi Lite interface ports
        -- Write address
        s_axi_awaddr : in std_logic_vector(31 downto 0); -- Write address
        s_axi_awvalid : in std_logic; -- Write address valid
        s_axi_awready : out std_logic; -- Write address ready
        
        -- Write data
        s_axi_wdata : in std_logic_vector(31 downto 0); -- Write data
        s_axi_wvalid : in std_logic; -- Write data valid
        s_axi_wready : out std_logic; -- Write data ready
        s_axi_wstrb : in std_logic_vector(3 downto 0); -- Write strobes
        
        -- Write response
        s_axi_bresp : out std_logic_vector(1 downto 0); -- Write response
        s_axi_bvalid : out std_logic; -- Write response valid
        s_axi_bready : in std_logic; -- Write response ready
        
        -- Read address
        s_axi_araddr : in std_logic_vector(31 downto 0); -- Read address
        s_axi_arvalid : in std_logic; -- Read address valid
        s_axi_arready : out std_logic; -- Read address ready
        
        -- Read data
        s_axi_rdata : out std_logic_vector(31 downto 0); -- Read data
        s_axi_rresp : out std_logic_vector(1 downto 0); -- Read response
        s_axi_rvalid : out std_logic; -- Read response valid
        s_axi_rready : in std_logic; -- Read response ready

        -- External DSP interface ports
        -- Control signals
        dsp_enable : out std_logic; -- Signal to enable DSP processing
        dsp_reset : in std_logic; -- Signal to reset DSP
        dsp_mode : out std_logic_vector(1 downto 0); -- Mode selection for DSP operation
        
        -- Streaming data signals
        dsp_data_in : out std_logic_vector(31 downto 0); -- Data
        dsp_data_in_valid: out std_logic; -- Signal indicating valid data on dsp_data_in
        dsp_data_in_ready: in std_logic; -- Signal indicating DSP is ready to accept data

        dsp_data_out : in std_logic_vector(31 downto 0); -- Processed data from DSP
        dsp_data_out_valid : in std_logic; -- Signal indicating valid data on dsp_data_out
        dsp_data_out_ready : out std_logic; -- Signal indicating ready to accept data from DSP   
        
        -- Coefficients
        dsp_coeff_data : out std_logic_vector(31 downto 0); -- Coefficient data for DSP
        dsp_coeff_addr : out std_logic_vector(7 downto 0); -- Coefficient address for DSP
        dsp_coeff_we : out std_logic -- Coefficient write enable signal for DSP
    );
end entity top_level_wrapper;

architecture structural of top_level_wrapper is
begin
end architecture;