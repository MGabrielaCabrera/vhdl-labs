--------------------------------------------------------------------------------
-- Engineer:    Gabriela Cabrera
--
-- Design:      Control FSM for external FIR DSP module
-- Module:      control_fsm
-- Description: Governs the operational sequencing of an external FIR DSP module.
--              Configured by SW through registers: enables/resets the filter,
--              sets the operating mode, loads filter coefficients, and streams
--              input samples one by one. Implements a three-process Mealy FSM.
-- Date:        09/03/2026
-- Version:     1.0
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity control_fsm is
    port (
        -- Clock and reset
        clk   : in  std_logic;
        rst_n : in  std_logic;

        -- DSP control outputs
        dsp_enable : out std_logic;
        dsp_reset  : out std_logic;
        dsp_mode   : out std_logic_vector(1 downto 0);

        -- DSP streaming input (to DSP)
        dsp_data_in       : out std_logic_vector(15 downto 0);
        dsp_data_in_valid : out std_logic;
        dsp_data_in_ready : in  std_logic;

        -- DSP streaming output (from DSP)
        dsp_data_out       : in  std_logic_vector(15 downto 0);
        dsp_data_out_valid : in  std_logic;
        dsp_data_out_ready : out std_logic;

        -- DSP coefficient interface
        dsp_coeff_data : out std_logic_vector(15 downto 0);
        dsp_coeff_addr : out std_logic_vector(7 downto 0);
        dsp_coeff_we   : out std_logic;

        -- Register map inputs (from AXI-Lite memory map)
        reg_enable           : in  std_logic;
        reg_reset            : in  std_logic;
        reg_mode             : in  std_logic_vector(1 downto 0); -- 00=Normal FIR, 01=Bypass, 10=Test pattern, 11=Reserved
        reg_coeff_data       : in  std_logic_vector(15 downto 0);
        reg_coeff_addr       : in  std_logic_vector(7 downto 0);
        reg_data_in          : in  std_logic_vector(31 downto 0);
        sample_write_strobe  : in  std_logic;
        coeff_write_strobe   : in  std_logic;

        -- Register map outputs (to AXI-Lite memory map)
        -- bit 0: ready | bit 1: error | bit 2: busy
        reg_status  : out std_logic_vector(2 downto 0);
        reg_data_out : out std_logic_vector(31 downto 0);
        reg_data_out_strobe : out std_logic
    );
end entity control_fsm;

architecture rtl of control_fsm is

    -- FSM state definition
    type t_state is (IDLE, SEND, WAIT_RESULT, LOAD_COEFF);

    signal current_state : t_state := IDLE;
    signal next_state    : t_state := IDLE;

    -- Internal registered outputs (driven by output process, registered by
    -- state register process)
    signal reg_data_out_int   : std_logic_vector(31 downto 0) := (others => '0');
    signal sample_reg_data_int : std_logic_vector(31 downto 0) := (others => '0');
    signal reg_data_out_strobe_int : std_logic := '0';
    signal dsp_data_out_ready_int : std_logic := '0';
    signal dsp_data_out_valid_last : std_logic := '0';

begin

    -- Process 1: State register
    -- Advances current_state to next_state on every rising clock edge.
    -- Asynchronous active-low reset returns to IDLE.
    p_state_reg : process(clk, rst_n)
    begin
        if rst_n = '0' then
            current_state <= IDLE;
        elsif rising_edge(clk) then
            current_state <= next_state;
        end if;
    end process p_state_reg;

    -- Process 2: Next-state logic (combinational)
    -- Computes the next state based on current state and inputs:
    --   sample_write_strobe, coeff_write_strobe,
    --   dsp_data_in_ready, dsp_data_out_valid, reg_enable
    p_next_state : process(all)
    begin

        case current_state is

            -- -----------------------------------------------------------------
            when IDLE =>
                if coeff_write_strobe = '1' and reg_enable = '0' then
                    -- Coefficient load requested and DSP is disabled
                    next_state <= LOAD_COEFF;
                elsif sample_write_strobe = '1' and reg_enable = '1' then
                    -- New input sample available and DSP is enabled
                    next_state <= SEND;
                end if;

            -- -----------------------------------------------------------------
            when SEND =>
                if dsp_data_in_ready = '1' then
                    -- DSP accepted the sample, wait for the result
                    next_state <= WAIT_RESULT;
                end if;

            -- -----------------------------------------------------------------
            when WAIT_RESULT =>
                if dsp_data_out_valid = '1' then
                    -- Result is available, return to IDLE
                    next_state <= IDLE;
                end if;

            -- -----------------------------------------------------------------
            when LOAD_COEFF =>
                -- Coefficient write is a single-cycle pulse; return immediately
                next_state <= IDLE;

            -- -----------------------------------------------------------------
            when others =>
                next_state <= IDLE;

        end case;
    end process p_next_state;

    -- Passthrough: always mirror register map
    dsp_enable <= reg_enable;
    dsp_reset  <= reg_reset;
    dsp_mode   <= reg_mode;

    -- Process 3: Output logic (Mealy based on next_state)
    -- All DSP control outputs are driven combinationally from next_state so
    -- that they are valid in the same cycle the state is entered.
    p_outputs : process(all)
    begin
        -- ---------------------------------------------------------------------
        -- Defaults (avoid latches)
        -- ---------------------------------------------------------------------
        dsp_data_in        <= (others => '0');
        dsp_coeff_data     <= (others => '0');
        dsp_coeff_addr     <= (others => '0');
        dsp_coeff_we       <= '0';

        -- ---------------------------------------------------------------------
        -- Output assignments based on NEXT state (Mealy)
        -- ---------------------------------------------------------------------
        case next_state is
            -- -----------------------------------------------------------------
            when IDLE =>
                dsp_data_in_valid <= '0';

            -- -----------------------------------------------------------------
            when SEND =>
                dsp_data_in       <= sample_reg_data_int(15 downto 0);
                dsp_data_in_valid <= '1';

            -- -----------------------------------------------------------------
            when WAIT_RESULT =>
                dsp_data_in_valid <= '0';

            -- -----------------------------------------------------------------
            when LOAD_COEFF =>
                dsp_coeff_data <= reg_coeff_data;
                dsp_coeff_addr <= reg_coeff_addr;
                dsp_coeff_we   <= '1';
                
                -- Just to avoid a latch on this signal, even though it won't be used in this state
                dsp_data_in_valid <= '0';

            -- -----------------------------------------------------------------
            when others =>
                -- Just to avoid a latch on this signal
                dsp_data_in_valid <= '0';
        end case;
    end process p_outputs;

    reg_status(0) <= '1' when (next_state = IDLE and coeff_write_strobe = '0' and sample_write_strobe = '0')
                            else '0'; -- ready bit
    reg_status(1) <= '1' when (next_state = IDLE and coeff_write_strobe = '1' and reg_enable = '1') or
                            (next_state = IDLE and sample_write_strobe = '1' and reg_enable = '0') else '0'; -- error bit
    reg_status(2) <= '1' when (next_state = SEND) or (next_state = WAIT_RESULT) or (next_state = LOAD_COEFF) else '0'; -- busy bit

    -- Registered internal signals
    -- reg_data_out_int holds the last captured DSP output across cycles so
    -- that reg_data_out remains stable between results.
    p_reg_capture : process(clk, rst_n)
    begin
        if rst_n = '0' then
            reg_data_out_int <= (others => '0');
            dsp_data_out_ready_int <= '0';
            reg_data_out_strobe_int <= '0';
        elsif rising_edge(clk) then
            dsp_data_out_valid_last <= dsp_data_out_valid;
            if dsp_data_out_valid = '1' and dsp_data_out_valid_last = '0' then
                reg_data_out_int <= std_logic_vector(
                                        resize(unsigned(dsp_data_out), 32));
                dsp_data_out_ready_int <= '1';
                reg_data_out_strobe_int <= '1';
            else
                dsp_data_out_ready_int <= '0';
                reg_data_out_strobe_int <= '0';
            end if;
            
            -- Capture the input sample into an internal register to avoid problems 
            -- if it is changed during the handshakes.
            if sample_write_strobe = '1' and reg_enable = '1' then
                sample_reg_data_int <= reg_data_in;
            end if;
     
        end if;
    end process p_reg_capture;

    reg_data_out <= reg_data_out_int;
    reg_data_out_strobe <= reg_data_out_strobe_int;
    dsp_data_out_ready <= dsp_data_out_ready_int;


end architecture rtl;
