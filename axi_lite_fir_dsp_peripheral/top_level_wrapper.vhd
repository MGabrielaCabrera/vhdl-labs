--------------------------------------------------------------------------------
-- Engineer:    Gabriela Cabrera
-- 
-- Design:     Top-Level Wrapper
-- Module:      top_level_wrapper
-- Description: The top-level module defines the external interface of the peripheral 
--              and structurally integrates all internal submodules. It instantiates 
--              the AXI-Lite slave interface, register bank and control finite state
--              machine, interconnecting them through clearly defined signals. 
--              This module contains no behavioral
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
        dsp_reset : out std_logic; -- Signal to reset DSP
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
    -- Internal signals for interconnecting submodules
    signal reg_enable : std_logic;
    signal reg_reset : std_logic;
    signal reg_mode : std_logic_vector(1 downto 0);
    signal reg_coeff_data : std_logic_vector(15 downto 0);
    signal reg_coeff_addr : std_logic_vector(7 downto 0);
    signal reg_data_in : std_logic_vector(31 downto 0);
    signal sample_write_strobe : std_logic;
    signal coeff_write_strobe : std_logic;
    signal reg_write_en : std_logic;
    signal reg_read_en : std_logic;
    signal reg_waddr : std_logic_vector(31 downto 0);
    signal reg_raddr : std_logic_vector(31 downto 0);
    signal reg_wdata : std_logic_vector(31 downto 0);
    signal reg_rdata : std_logic_vector(31 downto 0);
    signal dsp_coeff_data_int : std_logic_vector(15 downto 0);
    signal dsp_data_in_int : std_logic_vector(15 downto 0);

    signal reg_status : std_logic_vector(2 downto 0);
    signal reg_data_out : std_logic_vector(31 downto 0);
    signal reg_data_out_strobe : std_logic;

begin
    -- Instantiate AXI-Lite slave interface
    axi_lite_slave_inst : entity work.axi_lite_slave_if
        port map (
            clk => clk,
            rst_n => rst_n,

            -- Axi Lite interface ports
            s_axi_awaddr => s_axi_awaddr,
            s_axi_awvalid => s_axi_awvalid,
            s_axi_awready => s_axi_awready,
            s_axi_wdata => s_axi_wdata,
            s_axi_wvalid => s_axi_wvalid,
            s_axi_wready => s_axi_wready,
            s_axi_wstrb => s_axi_wstrb,
            s_axi_bresp => s_axi_bresp,
            s_axi_bvalid => s_axi_bvalid,
            s_axi_bready => s_axi_bready,
            s_axi_araddr => s_axi_araddr,
            s_axi_arvalid => s_axi_arvalid,
            s_axi_arready => s_axi_arready,
            s_axi_rdata => s_axi_rdata,
            s_axi_rresp => s_axi_rresp,
            s_axi_rvalid => s_axi_rvalid,
            s_axi_rready => s_axi_rready,

            -- Internal control signals to register bank
            reg_write_en => reg_write_en,
            reg_read_en => reg_read_en,
            reg_waddr => reg_waddr,
            reg_raddr => reg_raddr,
            reg_wdata => reg_wdata,
            reg_rdata => reg_rdata
        );

    -- Instantiate register bank
    register_bank_inst : entity work.register_bank
        port map (
            clk => clk,
            rst_n => rst_n,

            -- AXI-Lite slave interface (from axi_lite_slave_if)
            reg_write_en => reg_write_en,
            reg_read_en => reg_read_en,
            reg_waddr => reg_waddr,
            reg_raddr => reg_raddr,
            reg_wdata => reg_wdata,
            reg_rdata => reg_rdata,

            -- Outputs to DSP control FSM
            reg_enable => reg_enable,
            reg_reset => reg_reset,
            reg_mode => reg_mode,
            reg_coeff_data => reg_coeff_data,
            reg_coeff_addr => reg_coeff_addr,
            reg_data_in => reg_data_in,
            sample_write_strobe => sample_write_strobe,
            coeff_write_strobe => coeff_write_strobe,

            -- Inputs from DSP control FSM
            reg_status => reg_status,
            reg_data_out => reg_data_out,
            reg_data_out_strobe => reg_data_out_strobe
        );

    -- Instantiate control FSM
    control_fsm_inst : entity work.control_fsm
        port map (
            clk => clk,
            rst_n => rst_n,

            -- DSP control outputs
            dsp_enable => dsp_enable,
            dsp_reset => dsp_reset,
            dsp_mode => dsp_mode,

            -- DSP streaming input (to DSP)
            dsp_data_in => dsp_data_in_int(15 downto 0), -- Connect lower 16 bits for data input
            dsp_data_in_valid => dsp_data_in_valid,
            dsp_data_in_ready => dsp_data_in_ready,

            -- DSP streaming output (from DSP)
            dsp_data_out => dsp_data_out(15 downto 0), -- Connect lower 16 bits for data output
            dsp_data_out_valid => dsp_data_out_valid,
            dsp_data_out_ready => dsp_data_out_ready,

            -- DSP coefficient interface
            dsp_coeff_data => dsp_coeff_data_int(15 downto 0), -- Connect lower 16 bits for coefficient data
            dsp_coeff_addr => dsp_coeff_addr,
            dsp_coeff_we => dsp_coeff_we,

            -- Register map inputs (from AXI-Lite memory map)
            reg_enable => reg_enable,
            reg_reset => reg_reset,
            reg_mode => reg_mode,
            reg_coeff_data => reg_coeff_data,
            reg_coeff_addr => reg_coeff_addr,
            reg_data_in => reg_data_in,
            sample_write_strobe => sample_write_strobe,
            coeff_write_strobe => coeff_write_strobe,

            -- Register map outputs (to AXI-Lite memory map)
            reg_status => reg_status,
            reg_data_out => reg_data_out,
            reg_data_out_strobe => reg_data_out_strobe
        );

        dsp_coeff_data <= X"0000" & dsp_coeff_data_int; -- Extend 16-bit coefficient data to 32 bits for DSP interface
        dsp_data_in <= X"0000" & dsp_data_in_int(15 downto 0); -- Extend 16-bit data input to 32 bits for DSP interface

end architecture;