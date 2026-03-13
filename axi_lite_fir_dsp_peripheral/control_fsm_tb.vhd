--------------------------------------------------------------------------------
-- Engineer:    Gabriela Cabrera
--
-- Design:      Testbench - Control FSM for external FIR DSP module
-- Module:      control_fsm_tb
-- Description: Functional testbench with assertions covering:
--                T1  - Reset state
--                T2  - Passthrough signals mirror the register map
--                T3  - Coefficient write when enable = 0 (valid path)
--                T4  - Coefficient write when enable = 1 (blocked path)
--                T5  - Sample send with enable = 1 (full data path)
--                T6  - Sample send with enable = 0 (blocked path)
--                T7  - FSM stays in WAIT_RESULT until dsp_data_out_valid
--                T8  - dsp_data_out_ready pulse width is exactly one cycle
--                T9  - dsp_mode updates while FSM is in an active state
--                T10 - Back-to-back coefficient writes
-- Date:        09/03/2026
-- Version:     1.0
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity control_fsm_tb is
end entity control_fsm_tb;

architecture tb of control_fsm_tb is

    -- Constants
    constant CLK_PERIOD : time := 10 ns;

    -- DUT interface signals
    signal clk   : std_logic := '0';
    signal rst_n : std_logic := '0';

    -- DSP control (passthrough outputs)
    signal dsp_enable : std_logic;
    signal dsp_reset  : std_logic;
    signal dsp_mode   : std_logic_vector(1 downto 0);

    -- DSP streaming input
    signal dsp_data_in       : std_logic_vector(15 downto 0);
    signal dsp_data_in_valid : std_logic;
    signal dsp_data_in_ready : std_logic := '0';

    -- DSP streaming output
    signal dsp_data_out       : std_logic_vector(15 downto 0) := (others => '0');
    signal dsp_data_out_valid : std_logic                     := '0';
    signal dsp_data_out_ready : std_logic;

    -- DSP coefficient interface
    signal dsp_coeff_data : std_logic_vector(15 downto 0);
    signal dsp_coeff_addr : std_logic_vector(7 downto 0);
    signal dsp_coeff_we   : std_logic;

    -- Register map inputs
    signal reg_enable          : std_logic                     := '0';
    signal reg_reset           : std_logic                     := '0';
    signal reg_mode            : std_logic_vector(1 downto 0)  := "00";
    signal reg_coeff_data      : std_logic_vector(15 downto 0) := (others => '0');
    signal reg_coeff_addr      : std_logic_vector(7 downto 0)  := (others => '0');
    signal reg_data_in         : std_logic_vector(31 downto 0) := (others => '0');
    signal sample_write_strobe : std_logic                     := '0';
    signal coeff_write_strobe  : std_logic                     := '0';

    -- Register map outputs
    signal reg_status          : std_logic_vector(2 downto 0);
    signal reg_data_out        : std_logic_vector(31 downto 0);
    signal reg_data_out_strobe : std_logic;

    -- Component declaration
    component control_fsm is
        port (
            clk                 : in  std_logic;
            rst_n               : in  std_logic;
            dsp_enable          : out std_logic;
            dsp_reset           : out std_logic;
            dsp_mode            : out std_logic_vector(1 downto 0);
            dsp_data_in         : out std_logic_vector(15 downto 0);
            dsp_data_in_valid   : out std_logic;
            dsp_data_in_ready   : in  std_logic;
            dsp_data_out        : in  std_logic_vector(15 downto 0);
            dsp_data_out_valid  : in  std_logic;
            dsp_data_out_ready  : out std_logic;
            dsp_coeff_data      : out std_logic_vector(15 downto 0);
            dsp_coeff_addr      : out std_logic_vector(7 downto 0);
            dsp_coeff_we        : out std_logic;
            reg_enable          : in  std_logic;
            reg_reset           : in  std_logic;
            reg_mode            : in  std_logic_vector(1 downto 0);
            reg_coeff_data      : in  std_logic_vector(15 downto 0);
            reg_coeff_addr      : in  std_logic_vector(7 downto 0);
            reg_data_in         : in  std_logic_vector(31 downto 0);
            sample_write_strobe : in  std_logic;
            coeff_write_strobe  : in  std_logic;
            reg_status          : out std_logic_vector(2 downto 0);
            reg_data_out        : out std_logic_vector(31 downto 0);
            reg_data_out_strobe : out std_logic
        );
    end component control_fsm;

begin

    -- Clock generation: starts LOW, toggles every half period
	-- Clock generation
	clk_process : process
	begin
		while now < 1000 ns loop
			clk <= '1'; wait for CLK_PERIOD/2;
			clk <= '0'; wait for CLK_PERIOD/2;
		end loop;
		wait;
	end process;

    -- DUT instantiation
    dut : control_fsm
        port map (
            clk                 => clk,
            rst_n               => rst_n,
            dsp_enable          => dsp_enable,
            dsp_reset           => dsp_reset,
            dsp_mode            => dsp_mode,
            dsp_data_in         => dsp_data_in,
            dsp_data_in_valid   => dsp_data_in_valid,
            dsp_data_in_ready   => dsp_data_in_ready,
            dsp_data_out        => dsp_data_out,
            dsp_data_out_valid  => dsp_data_out_valid,
            dsp_data_out_ready  => dsp_data_out_ready,
            dsp_coeff_data      => dsp_coeff_data,
            dsp_coeff_addr      => dsp_coeff_addr,
            dsp_coeff_we        => dsp_coeff_we,
            reg_enable          => reg_enable,
            reg_reset           => reg_reset,
            reg_mode            => reg_mode,
            reg_coeff_data      => reg_coeff_data,
            reg_coeff_addr      => reg_coeff_addr,
            reg_data_in         => reg_data_in,
            sample_write_strobe => sample_write_strobe,
            coeff_write_strobe  => coeff_write_strobe,
            reg_status          => reg_status,
            reg_data_out        => reg_data_out,
            reg_data_out_strobe => reg_data_out_strobe
        );

    -- Stimulus process
    -- Driving convention:
    --   Inputs are driven after the falling edge (mid-cycle) so the DUT sees
    --   them stable before the next rising edge. Outputs are sampled after the
    --   following falling edge, once the registered DUT outputs have settled.
    stim_proc : process

        procedure clk_rise is
        begin
            wait until rising_edge(clk);
        end procedure;

        procedure clk_fall is
        begin
            wait until falling_edge(clk);
        end procedure;

        -- Drop all strobes and advance one full cycle
        procedure idle_cycle is
        begin
            clk_fall;
            sample_write_strobe <= '0';
            coeff_write_strobe  <= '0';
            clk_rise;
        end procedure;

    begin

        -----------------------------------------------------------------------
        -- Test 1 : Reset state
        -- All registered outputs must be at their safe reset values while
        -- rst_n is held low.
        -----------------------------------------------------------------------
        report "Test 1: Verifying output values during active reset (rst_n=0)";

        rst_n               <= '0';
        reg_enable          <= '0';
        reg_reset           <= '0';
        reg_mode            <= "00";
        reg_coeff_data      <= x"0000";
        reg_coeff_addr      <= x"00";
        reg_data_in         <= x"00000000";
        sample_write_strobe <= '0';
        coeff_write_strobe  <= '0';
        dsp_data_in_ready   <= '0';
        dsp_data_out_valid  <= '0';
        dsp_data_out        <= x"0000";

        -- Hold reset for three clock cycles then check on a falling edge
        clk_rise; clk_rise; clk_rise;
        clk_fall;

        assert dsp_enable         = '0'
            report "FAIL T1: dsp_enable should be '0' in reset"         severity error;
        assert dsp_reset          = '0'
            report "FAIL T1: dsp_reset should be '0' in reset"          severity error;
        assert dsp_mode           = "00"
            report "FAIL T1: dsp_mode should be 00 in reset"            severity error;
        assert dsp_data_in_valid  = '0'
            report "FAIL T1: dsp_data_in_valid should be '0' in reset"  severity error;
        assert dsp_data_out_ready = '0'
            report "FAIL T1: dsp_data_out_ready should be '0' in reset" severity error;
        assert dsp_coeff_we       = '0'
            report "FAIL T1: dsp_coeff_we should be '0' in reset"       severity error;
        assert reg_status         = "001"
            report "FAIL T1: reg_status should be 001 (ready) in reset" severity error;

        -- Release reset and let the FSM settle for two cycles
        clk_fall;
        rst_n <= '1';
        clk_rise; clk_rise;

        -----------------------------------------------------------------------
        -- Test 2 : Passthrough signals always mirror the register map
        -- dsp_enable, dsp_reset and dsp_mode must follow reg_enable,
        -- reg_reset and reg_mode on the very next registered clock edge,
        -- regardless of FSM state.
        -----------------------------------------------------------------------
        report "Test 2: Verifying passthrough signals mirror reg_enable/reg_reset/reg_mode";

        -- First combination: all asserted, mode = "10"
        clk_fall;
        reg_enable <= '1'; reg_reset <= '1'; reg_mode <= "10";
        clk_rise;   -- outputs registered on this edge
        clk_fall;

        assert dsp_enable = '1'
            report "FAIL T2a: dsp_enable should follow reg_enable=1"  severity error;
        assert dsp_reset  = '1'
            report "FAIL T2a: dsp_reset should follow reg_reset=1"    severity error;
        assert dsp_mode   = "10"
            report "FAIL T2a: dsp_mode should follow reg_mode=10"     severity error;

        -- Second combination: all deasserted, mode = "01"
        clk_fall;
        reg_enable <= '0'; reg_reset <= '0'; reg_mode <= "01";
        clk_rise;
        clk_fall;

        assert dsp_enable = '0'
            report "FAIL T2b: dsp_enable should follow reg_enable=0"  severity error;
        assert dsp_reset  = '0'
            report "FAIL T2b: dsp_reset should follow reg_reset=0"    severity error;
        assert dsp_mode   = "01"
            report "FAIL T2b: dsp_mode should follow reg_mode=01"     severity error;

        -- Restore defaults
        clk_fall;
        reg_enable <= '0'; reg_reset <= '0'; reg_mode <= "00";
        clk_rise;

        -----------------------------------------------------------------------
        -- Test 3 : Coefficient write when enable = 0  (valid path)
        -- Expected: FSM transitions IDLE -> LOAD_COEFF -> IDLE.
        -- dsp_coeff_we is pulsed HIGH for exactly one cycle with the correct
        -- data and address forwarded; status is BUSY in LOAD_COEFF and READY
        -- immediately after.
        -----------------------------------------------------------------------
        report "Test 3: Verifying coefficient write with enable=0 (valid path)";

        clk_fall;
        reg_enable         <= '0';
        reg_coeff_data     <= x"1234";
        reg_coeff_addr     <= x"05";
        coeff_write_strobe <= '1';

        clk_rise;   -- FSM: IDLE -> LOAD_COEFF, outputs registered
        coeff_write_strobe <= '0';

        assert dsp_coeff_we   = '1'
            report "FAIL T3: dsp_coeff_we should be '1' in LOAD_COEFF"      severity error;
        assert dsp_coeff_data = x"1234"
            report "FAIL T3: dsp_coeff_data should be 0x1234 in LOAD_COEFF" severity error;
        assert dsp_coeff_addr = x"05"
            report "FAIL T3: dsp_coeff_addr should be 0x05 in LOAD_COEFF"   severity error;
        assert reg_status     = "100"
            report "FAIL T3: reg_status should be 100 (busy) in LOAD_COEFF" severity error;

        clk_rise;   -- FSM: LOAD_COEFF -> IDLE
        clk_fall;

        assert dsp_coeff_we = '0'
            report "FAIL T3: dsp_coeff_we should be '0' back in IDLE"       severity error;
        assert reg_status   = "001"
            report "FAIL T3: reg_status should be 001 (ready) back in IDLE" severity error;

        -----------------------------------------------------------------------
        -- Test 4 : Coefficient write when enable = 1  (blocked path)
        -- Expected: FSM stays in IDLE, dsp_coeff_we is never asserted,
        -- and status reflects the error condition (bit 1 set).
        -----------------------------------------------------------------------
        report "Test 4: Verifying coefficient write is blocked when enable=1";

        clk_fall;
        reg_enable         <= '1';
        reg_coeff_data     <= x"ABCD";
        reg_coeff_addr     <= x"0A";
        coeff_write_strobe <= '1';

        clk_rise;
        clk_fall;
        coeff_write_strobe <= '0';

        assert dsp_coeff_we = '0'
            report "FAIL T4: dsp_coeff_we must stay '0' when coeff write attempted with enable=1"
            severity error;
        assert reg_status   = "010"
            report "FAIL T4: reg_status should be 010 (error) when coeff write blocked"
            severity error;

        -- Restore
        clk_fall;
        reg_enable <= '0';
        clk_rise;
        idle_cycle;

        -----------------------------------------------------------------------
        -- Test 5 : Send data_in with enable = 1  (full data path)
        -- Expected sequence:
        --   IDLE -> SEND        : dsp_data_in_valid='1', correct sample,
        --                         status BUSY; valid held while waiting for ready
        --   SEND -> WAIT_RESULT : valid deasserted, status BUSY
        --   WAIT_RESULT -> IDLE : result captured into reg_data_out,
        --                         dsp_data_out_ready pulsed ONE cycle,
        --                         reg_data_out_strobe pulsed ONE cycle,
        --                         status READY
        -----------------------------------------------------------------------
        report "Test 5: Verifying full data path (enable=1, send sample, receive result)";

        clk_fall;
        reg_enable          <= '1';
        reg_data_in         <= x"0000BEEF";
        sample_write_strobe <= '1';

        clk_rise;   -- FSM: IDLE -> SEND
        clk_fall;
        sample_write_strobe <= '0';

        -- SEND state checks
        assert dsp_data_in_valid = '1'
            report "FAIL T5: dsp_data_in_valid should be '1' in SEND"        severity error;
        assert dsp_data_in       = x"BEEF"
            report "FAIL T5: dsp_data_in should be 0xBEEF in SEND"           severity error;
        assert reg_status        = "100"
            report "FAIL T5: reg_status should be 100 (busy) in SEND"        severity error;

        -- Hold for one extra cycle to verify valid is maintained (back-pressure)
        clk_rise; clk_fall;

        assert dsp_data_in_valid = '1'
            report "FAIL T5: dsp_data_in_valid should remain '1' while waiting for ready"
            severity error;

        -- DSP asserts ready -> handshake completes
        clk_fall;
        dsp_data_in_ready <= '1';

        clk_rise;   -- FSM: SEND -> WAIT_RESULT
        clk_fall;
        dsp_data_in_ready <= '0';

        assert dsp_data_in_valid = '0'
            report "FAIL T5: dsp_data_in_valid should be '0' in WAIT_RESULT"         severity error;
        assert reg_status        = "100"
            report "FAIL T5: reg_status should remain 100 (busy) in WAIT_RESULT"     severity error;

        -- DSP produces the result
        clk_fall;
        dsp_data_out       <= x"1234";
        dsp_data_out_valid <= '1';

        clk_rise;   -- FSM: WAIT_RESULT -> IDLE, output captured
        clk_fall;
        dsp_data_out_valid <= '0';

        -- Capture cycle: ready and strobe pulsed, data correct, status READY
        assert dsp_data_out_ready  = '1'
            report "FAIL T5: dsp_data_out_ready should be '1' on capture cycle"  severity error;
        assert reg_data_out_strobe = '1'
            report "FAIL T5: reg_data_out_strobe should be '1' on capture cycle" severity error;
        assert reg_data_out        = x"00001234"
            report "FAIL T5: reg_data_out should be 0x00001234"                   severity error;
        assert reg_status          = "001"
            report "FAIL T5: reg_status should be 001 (ready) after result captured"
            severity error;

        -- One cycle later: single-cycle pulses must be gone
        clk_rise; clk_fall;

        assert dsp_data_out_ready  = '0'
            report "FAIL T5: dsp_data_out_ready should be '0' one cycle after capture"
            severity error;
        assert reg_data_out_strobe = '0'
            report "FAIL T5: reg_data_out_strobe should be '0' one cycle after capture"
            severity error;

        -- Restore
        clk_fall;
        reg_enable <= '0';
        clk_rise;
        idle_cycle;

        -----------------------------------------------------------------------
        -- Test 6 : Send data_in with enable = 0  (blocked path)
        -- Expected: FSM stays in IDLE, dsp_data_in_valid is never asserted,
        -- dsp_data_out_ready stays low and status indicates error.
        -----------------------------------------------------------------------
        report "Test 6: Verifying sample write is blocked when enable=0";

        clk_fall;
        reg_enable          <= '0';
        reg_data_in         <= x"0000DEAD";
        sample_write_strobe <= '1';

        clk_rise;
        clk_fall;
        sample_write_strobe <= '0';

        assert dsp_data_in_valid  = '0'
            report "FAIL T6: dsp_data_in_valid must be '0' when enable=0"  severity error;
        assert dsp_data_out_ready = '0'
            report "FAIL T6: dsp_data_out_ready must be '0' when enable=0" severity error;
        assert reg_status         = "010"
            report "FAIL T6: reg_status should be 010 (error) for sample write with enable=0"
            severity error;

        idle_cycle;

        -----------------------------------------------------------------------
        -- Test 7 : FSM holds in WAIT_RESULT until dsp_data_out_valid arrives
        -- Status must remain BUSY across multiple waiting cycles with no
        -- premature state transition.
        -----------------------------------------------------------------------
        report "Test 7: Verifying FSM stays in WAIT_RESULT until result is valid";

        clk_fall;
        reg_enable          <= '1';
        reg_data_in         <= x"00001111";
        sample_write_strobe <= '1';

        clk_rise;   -- IDLE -> SEND
        clk_fall;
        sample_write_strobe <= '0';
        dsp_data_in_ready   <= '1';

        clk_rise;   -- SEND -> WAIT_RESULT
        clk_fall;
        dsp_data_in_ready <= '0';

        -- Verify FSM holds WAIT_RESULT for four consecutive cycles
        for cycle in 1 to 4 loop
            assert reg_status = "100"
                report "FAIL T7: reg_status should be 100 (busy) in WAIT_RESULT, cycle "
                       & integer'image(cycle) severity error;
            assert dsp_data_in_valid = '0'
                report "FAIL T7: dsp_data_in_valid should be '0' in WAIT_RESULT, cycle "
                       & integer'image(cycle) severity error;
            clk_rise; clk_fall;
        end loop;

        -- Deliver result and check transition back to IDLE
        dsp_data_out       <= x"1111";
        dsp_data_out_valid <= '1';

        clk_rise;
        clk_fall;
        dsp_data_out_valid <= '0';

        assert reg_data_out = x"00001111"
            report "FAIL T7: reg_data_out should be 0x00001111 after result arrives" severity error;
        assert reg_status   = "001"
            report "FAIL T7: reg_status should be 001 (ready) after result captured" severity error;

        -- Restore
        clk_fall;
        reg_enable <= '0';
        clk_rise;
        idle_cycle;

        -----------------------------------------------------------------------
        -- Test 8 : dsp_data_out_ready pulse width is exactly one cycle
        -- Even if dsp_data_out_valid is held high for more than one cycle,
        -- dsp_data_out_ready must not stay asserted.
        -----------------------------------------------------------------------
        report "Test 8: Verifying dsp_data_out_ready is exactly one cycle wide";

        clk_fall;
        reg_enable          <= '1';
        reg_data_in         <= x"0000CAFE";
        sample_write_strobe <= '1';

        clk_rise; clk_fall;
        sample_write_strobe <= '0';
        dsp_data_in_ready   <= '1';

        clk_rise; clk_fall;
        dsp_data_in_ready  <= '0';
        dsp_data_out       <= x"CAFE";
        dsp_data_out_valid <= '1';  -- hold valid high for 2 cycles

        clk_rise; clk_fall;        -- capture cycle: ready should be '1'

        assert dsp_data_out_ready = '1'
            report "FAIL T8: dsp_data_out_ready should be '1' on the capture cycle"
            severity error;

        -- valid still high; ready must drop on the very next cycle
        clk_rise; clk_fall;
        dsp_data_out_valid <= '0';

        assert dsp_data_out_ready = '0'
            report "FAIL T8: dsp_data_out_ready must be '0' one cycle after capture (pulse must be 1 cycle)"
            severity error;

        -- Restore
        clk_fall;
        reg_enable <= '0';
        clk_rise;
        idle_cycle;

        -----------------------------------------------------------------------
        -- Test 9 : dsp_mode updates while the FSM is in an active state
        -- Changes to reg_mode must propagate to dsp_mode on the next clock
        -- edge even while the FSM is mid-transaction.
        -----------------------------------------------------------------------
        report "Test 9: Verifying dsp_mode passthrough updates during SEND state";

        clk_fall;
        reg_enable          <= '1';
        reg_mode            <= "00";
        reg_data_in         <= x"00005A5A";
        sample_write_strobe <= '1';

        clk_rise;   -- IDLE -> SEND
        clk_fall;
        sample_write_strobe <= '0';

        assert dsp_mode = "00"
            report "FAIL T9: dsp_mode should be 00 at entry to SEND" severity error;

        -- Change mode while inside SEND
        clk_fall;
        reg_mode <= "01";
        clk_rise; clk_fall;

        assert dsp_mode = "01"
            report "FAIL T9: dsp_mode should update to 01 while FSM is in SEND" severity error;

        clk_fall;
        reg_mode <= "10";
        clk_rise; clk_fall;

        assert dsp_mode = "10"
            report "FAIL T9: dsp_mode should update to 10 while FSM is in SEND" severity error;

        -- Complete the transaction cleanly
        dsp_data_in_ready <= '1';
        clk_rise; clk_fall;
        dsp_data_in_ready  <= '0';
        dsp_data_out       <= x"5A5A";
        dsp_data_out_valid <= '1';
        clk_rise; clk_fall;
        dsp_data_out_valid <= '0';
        clk_rise;

        -- Restore
        clk_fall;
        reg_enable <= '0'; reg_mode <= "00";
        clk_rise;
        idle_cycle;

        -----------------------------------------------------------------------
        -- Test 10 : Back-to-back coefficient writes
        -- Two consecutive writes with enable=0. Each must produce a clean
        -- one-cycle dsp_coeff_we pulse with independent data and address.
        -- The FSM must return to IDLE between the two writes.
        -----------------------------------------------------------------------
        report "Test 10: Verifying back-to-back coefficient writes";

        -- First write
        clk_fall;
        reg_enable         <= '0';
        reg_coeff_data     <= x"AAAA";
        reg_coeff_addr     <= x"01";
        coeff_write_strobe <= '1';

        clk_rise;   -- IDLE -> LOAD_COEFF (first write)
        coeff_write_strobe <= '0';

        assert dsp_coeff_we   = '1'
            report "FAIL T10: dsp_coeff_we should be '1' for first write"      severity error;
        assert dsp_coeff_data = x"AAAA"
            report "FAIL T10: dsp_coeff_data should be 0xAAAA for first write" severity error;
        assert dsp_coeff_addr = x"01"
            report "FAIL T10: dsp_coeff_addr should be 0x01 for first write"   severity error;
        assert reg_status     = "100"
            report "FAIL T10: reg_status should be 100 (busy) for first write" severity error;

        -- Queue the second write immediately

        clk_rise;   -- LOAD_COEFF -> IDLE  (we deasserted here)
        reg_coeff_data     <= x"BBBB";
        reg_coeff_addr     <= x"02";
        coeff_write_strobe <= '1';


        assert dsp_coeff_we = '0'
            report "FAIL T10: dsp_coeff_we should be '0' in IDLE between the two writes"
            severity error;
        assert reg_status   = "001"
            report "FAIL T10: reg_status should be 001 (ready) in IDLE between writes"
            severity error;
        clk_fall;
        coeff_write_strobe <= '0';
        clk_rise;   -- IDLE -> LOAD_COEFF (second write, strobe was held)

        assert dsp_coeff_we   = '1'
            report "FAIL T10: dsp_coeff_we should be '1' for second write"      severity error;
        assert dsp_coeff_data = x"BBBB"
            report "FAIL T10: dsp_coeff_data should be 0xBBBB for second write" severity error;
        assert dsp_coeff_addr = x"02"
            report "FAIL T10: dsp_coeff_addr should be 0x02 for second write"   severity error;

        clk_rise;   -- LOAD_COEFF -> IDLE

        assert dsp_coeff_we = '0'
            report "FAIL T10: dsp_coeff_we should be '0' after second write completes"
            severity error;
        assert reg_status   = "001"
            report "FAIL T10: reg_status should be 001 (ready) after all writes"
            severity error;

        -----------------------------------------------------------------------
        -- End of simulation
        -----------------------------------------------------------------------
        wait for CLK_PERIOD * 5;
        report "End of simulation - all tests passed" severity note;
        wait;

    end process stim_proc;

end architecture tb;
