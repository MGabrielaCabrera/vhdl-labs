--------------------------------------------------------------------------------
-- Engineer:    Gabriela Cabrera
--
-- Design:      Testbench - Register Bank
-- Module:      register_bank_tb
-- Description: Functional testbench with assertions:
--
--                T1  - Reset state: all registers and outputs at safe defaults
--                T2  - CTRL register write and readback (enable, reset, mode)
--                T3  - CTRL reserved bits are forced to zero on write
--                T4  - STATUS register is read-only (write ignored)
--                T5  - STATUS register updates when reg_status changes
--                T6  - COEFF_DATA write generates one-cycle coeff_write_strobe
--                T7  - COEFF_ADDR write generates one-cycle coeff_write_strobe
--                T8  - DATA_IN write generates one-cycle sample_write_strobe
--                T9  - DATA_OUT updated by reg_data_out_strobe (read-only)
--                T10 - Write priority over simultaneous read
-- Date:        13/03/2026
-- Version:     1.0
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity register_bank_tb is
end entity register_bank_tb;

architecture tb of register_bank_tb is

    constant CLK_PERIOD : time := 10 ns;

    -- Clock and reset
    signal clk   : std_logic := '0';
    signal rst_n : std_logic := '0';

    -- AXI-Lite interface
    signal reg_write_en : std_logic := '0';
    signal reg_read_en  : std_logic := '0';
    signal reg_waddr    : std_logic_vector(31 downto 0) := (others => '0');
    signal reg_raddr    : std_logic_vector(31 downto 0) := (others => '0');
    signal reg_wdata    : std_logic_vector(31 downto 0) := (others => '0');
    signal reg_rdata    : std_logic_vector(31 downto 0);

    -- Outputs to FSM
    signal reg_enable          : std_logic;
    signal reg_reset           : std_logic;
    signal reg_mode            : std_logic_vector(1 downto 0);
    signal reg_coeff_data      : std_logic_vector(15 downto 0);
    signal reg_coeff_addr      : std_logic_vector(7 downto 0);
    signal reg_data_in         : std_logic_vector(31 downto 0);
    signal sample_write_strobe : std_logic;
    signal coeff_write_strobe  : std_logic;

    -- Inputs from FSM
    signal reg_status          : std_logic_vector(2 downto 0) := "000";
    signal reg_data_out        : std_logic_vector(31 downto 0) := (others => '0');
    signal reg_data_out_strobe : std_logic := '0';

    -- Address constants (mirrored from DUT for readability)
    constant ADDR_CTRL       : std_logic_vector(31 downto 0) := x"00000000";
    constant ADDR_STATUS     : std_logic_vector(31 downto 0) := x"00000004";
    constant ADDR_COEFF_DATA : std_logic_vector(31 downto 0) := x"00000008";
    constant ADDR_COEFF_ADDR : std_logic_vector(31 downto 0) := x"0000000C";
    constant ADDR_DATA_IN    : std_logic_vector(31 downto 0) := x"00000010";
    constant ADDR_DATA_OUT   : std_logic_vector(31 downto 0) := x"00000014";

    component register_bank is
        port (
            clk                 : in  std_logic;
            rst_n               : in  std_logic;
            reg_write_en        : in  std_logic;
            reg_read_en         : in  std_logic;
            reg_waddr           : in  std_logic_vector(31 downto 0);
            reg_raddr           : in  std_logic_vector(31 downto 0);
            reg_wdata           : in  std_logic_vector(31 downto 0);
            reg_rdata           : out std_logic_vector(31 downto 0);
            reg_enable          : out std_logic;
            reg_reset           : out std_logic;
            reg_mode            : out std_logic_vector(1 downto 0);
            reg_coeff_data      : out std_logic_vector(15 downto 0);
            reg_coeff_addr      : out std_logic_vector(7 downto 0);
            reg_data_in         : out std_logic_vector(31 downto 0);
            sample_write_strobe : out std_logic;
            coeff_write_strobe  : out std_logic;
            reg_status          : in  std_logic_vector(2 downto 0);
            reg_data_out        : in  std_logic_vector(31 downto 0);
            reg_data_out_strobe : in  std_logic
        );
    end component register_bank;

begin

    -- Clock generation: starts LOW, toggles every half period
	-- Clock generation
	clk_process : process
	begin
		while now < 650 ns loop
			clk <= '1'; wait for CLK_PERIOD/2;
			clk <= '0'; wait for CLK_PERIOD/2;
		end loop;
		wait;
	end process;

    dut : register_bank
        port map (
            clk                 => clk,
            rst_n               => rst_n,
            reg_write_en        => reg_write_en,
            reg_read_en         => reg_read_en,
            reg_waddr           => reg_waddr,
            reg_raddr           => reg_raddr,
            reg_wdata           => reg_wdata,
            reg_rdata           => reg_rdata,
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

    stim_proc : process

        procedure clk_rise is
        begin
            wait until rising_edge(clk);
        end procedure;

        procedure clk_fall is
        begin
            wait until falling_edge(clk);
        end procedure;

        -- Perform a single-cycle register write, then deassert
        procedure reg_write (
            addr : in std_logic_vector(31 downto 0);
            data : in std_logic_vector(31 downto 0)
        ) is
        begin
            clk_fall;
            reg_write_en <= '1';
            reg_waddr    <= addr;
            reg_wdata    <= data;
            clk_rise;
            clk_fall;
            reg_write_en <= '0';
            reg_waddr    <= (others => '0');
            reg_wdata    <= (others => '0');
        end procedure;

        -- Perform a single-cycle register read, then deassert
        procedure reg_read (
            addr : in std_logic_vector(31 downto 0)
        ) is
        begin
            clk_fall;
            reg_read_en <= '1';
            reg_raddr   <= addr;
            -- reg_rdata is combinational: sample on this same falling edge
            -- after the combinational path settles
            wait for 1 ns;
        end procedure;

        -- Deassert read enable after sampling
        procedure reg_read_done is
        begin
            clk_fall;
            reg_read_en <= '0';
            reg_raddr   <= (others => '0');
        end procedure;

    begin

        -----------------------------------------------------------------------
        -- Test 1: Reset state
        -- All internal registers and output signals must be at their safe
        -- reset-state defaults while rst_n is held low.
        -----------------------------------------------------------------------
        report "Test 1: Verifying reset state";

        rst_n               <= '0';
        reg_write_en        <= '0';
        reg_read_en         <= '0';
        reg_waddr           <= (others => '0');
        reg_raddr           <= (others => '0');
        reg_wdata           <= (others => '0');
        reg_status          <= "000";
        reg_data_out        <= (others => '0');
        reg_data_out_strobe <= '0';

        clk_rise; clk_rise; clk_rise;
        clk_fall;

        assert reg_enable          = '0'
            report "FAIL T1: reg_enable should be '0' in reset"          severity error;
        assert reg_reset           = '0'
            report "FAIL T1: reg_reset should be '0' in reset"           severity error;
        assert reg_mode            = "00"
            report "FAIL T1: reg_mode should be 00 in reset"             severity error;
        assert reg_coeff_data      = x"0000"
            report "FAIL T1: reg_coeff_data should be 0x0000 in reset"   severity error;
        assert reg_coeff_addr      = x"00"
            report "FAIL T1: reg_coeff_addr should be 0x00 in reset"     severity error;
        assert reg_data_in         = x"00000000"
            report "FAIL T1: reg_data_in should be 0x00000000 in reset"  severity error;
        assert sample_write_strobe = '0'
            report "FAIL T1: sample_write_strobe should be '0' in reset" severity error;
        assert coeff_write_strobe  = '0'
            report "FAIL T1: coeff_write_strobe should be '0' in reset"  severity error;

        -- Release reset
        clk_fall;
        rst_n <= '1';
        clk_rise; clk_rise;

        -----------------------------------------------------------------------
        -- Test 2: CTRL register write and readback
        -- Writing to 0x00 must update reg_enable, reg_reset and reg_mode and
        -- the value must be readable back from the same address.
        -----------------------------------------------------------------------
        report "Test 2: Verifying CTRL register write and readback";

        -- Write: enable=1, reset=1, mode=10 -> wdata = 0b00001111 = 0x0F
        -- bit0=enable, bit1=reset, bit3:2=mode"10" -> 0b1011 = 0x0B
        reg_write(ADDR_CTRL, x"0000000B");  -- enable=1, reset=1, mode="10"

        clk_fall;

        assert reg_enable = '1'
            report "FAIL T2: reg_enable should be '1' after CTRL write"   severity error;
        assert reg_reset  = '1'
            report "FAIL T2: reg_reset should be '1' after CTRL write"    severity error;
        assert reg_mode   = "10"
            report "FAIL T2: reg_mode should be 10 after CTRL write"      severity error;

        -- Readback: reg_rdata should reflect the stored CTRL value
        clk_fall;
        reg_read_en <= '1';
        reg_raddr   <= ADDR_CTRL;
        wait for 1 ns;  -- allow combinational path to settle

        assert reg_rdata(0)          = '1'
            report "FAIL T2: CTRL readback bit0 (enable) should be '1'"  severity error;
        assert reg_rdata(1)          = '1'
            report "FAIL T2: CTRL readback bit1 (reset) should be '1'"   severity error;
        assert reg_rdata(3 downto 2) = "10"
            report "FAIL T2: CTRL readback bits[3:2] (mode) should be 10" severity error;
        assert reg_rdata(31 downto 4) = (27 downto 0 => '0')
            report "FAIL T2: CTRL readback reserved bits should be 0"     severity error;

        clk_fall;
        reg_read_en <= '0';

        -- Restore CTRL to default
        reg_write(ADDR_CTRL, x"00000000");

        -----------------------------------------------------------------------
        -- Test 3: CTRL reserved bits are forced to zero
        -- Writing 0xFFFFFFFF to CTRL must only store bits [3:0]; all upper
        -- bits must read back as zero.
        -----------------------------------------------------------------------
        report "Test 3: Verifying CTRL reserved bits are forced to zero";

        reg_write(ADDR_CTRL, x"FFFFFFFF");

        clk_fall;
        reg_read_en <= '1';
        reg_raddr   <= ADDR_CTRL;
        wait for 1 ns;

        assert reg_rdata(31 downto 4) = (27 downto 0 => '0')
            report "FAIL T3: CTRL reserved bits [31:4] must always read as zero" severity error;
        assert reg_rdata(3 downto 0) = "1111"
            report "FAIL T3: CTRL writable bits [3:0] should be 1111"            severity error;

        clk_fall;
        reg_read_en <= '0';

        -- Restore
        reg_write(ADDR_CTRL, x"00000000");

        -----------------------------------------------------------------------
        -- Test 4: STATUS register is read-only
        -- A write to 0x04 must be silently ignored; the STATUS register must
        -- not change as a result of a software write.
        -----------------------------------------------------------------------
        report "Test 4: Verifying STATUS register is read-only";

        -- Set a known FSM-driven status first
        clk_fall;
        reg_status <= "001";   -- ready
        clk_rise; clk_rise;

        -- Attempt to overwrite STATUS with all ones
        reg_write(ADDR_STATUS, x"FFFFFFFF");

        -- Read back STATUS: must still reflect the FSM value, not the write
        clk_fall;
        reg_read_en <= '1';
        reg_raddr   <= ADDR_STATUS;
        wait for 1 ns;

        assert reg_rdata(2 downto 0) = "001"
            report "FAIL T4: STATUS must not be overwritten by a software write" severity error;
        assert reg_rdata(31 downto 3) = (28 downto 0 => '0')
            report "FAIL T4: STATUS reserved bits must remain zero after write attempt"
            severity error;

        clk_fall;
        reg_read_en <= '0';

        -----------------------------------------------------------------------
        -- Test 5: STATUS register updates when reg_status changes
        -- Any change on the reg_status input from the FSM must be reflected
        -- in the readable STATUS register on the next clock edge.
        -----------------------------------------------------------------------
        report "Test 5: Verifying STATUS register tracks reg_status changes";

        -- Transition: ready -> busy
        clk_fall;
        reg_status <= "100";   -- busy
        clk_rise;              -- change detected and latched
        clk_fall;

        reg_read_en <= '1';
        reg_raddr   <= ADDR_STATUS;
        wait for 1 ns;

        assert reg_rdata(2 downto 0) = "100"
            report "FAIL T5a: STATUS should reflect reg_status=100 (busy)" severity error;

        clk_fall;
        reg_read_en <= '0';

        -- Transition: busy -> error
        clk_fall;
        reg_status <= "010";   -- error
        clk_rise;
        clk_fall;

        reg_read_en <= '1';
        reg_raddr   <= ADDR_STATUS;
        wait for 1 ns;

        assert reg_rdata(2 downto 0) = "010"
            report "FAIL T5b: STATUS should reflect reg_status=010 (error)" severity error;

        clk_fall;
        reg_read_en <= '0';

        -- Restore
        clk_fall;
        reg_status <= "001";
        clk_rise;

        -----------------------------------------------------------------------
        -- Test 6: COEFF_DATA write generates a one-cycle coeff_write_strobe
        -- The strobe must be high for exactly one clock cycle and the
        -- coefficient value must be available on reg_coeff_data.
        -----------------------------------------------------------------------
        report "Test 6: Verifying COEFF_DATA write generates one-cycle coeff_write_strobe";

        clk_fall;
        reg_write_en <= '1';
        reg_waddr    <= ADDR_COEFF_DATA;
        reg_wdata    <= x"00001234";

        clk_rise;   -- write registered, strobe asserted
        clk_fall;
        reg_write_en <= '0';

        assert coeff_write_strobe = '1'
            report "FAIL T6: coeff_write_strobe should be '1' on the write cycle"  severity error;
        assert reg_coeff_data     = x"1234"
            report "FAIL T6: reg_coeff_data should be 0x1234 after COEFF_DATA write"
            severity error;

        -- One cycle later: strobe must have dropped
        clk_rise;
        clk_fall;

        assert coeff_write_strobe = '0'
            report "FAIL T6: coeff_write_strobe should be '0' one cycle after write"
            severity error;

        -----------------------------------------------------------------------
        -- Test 7: COEFF_ADDR write generates a one-cycle coeff_write_strobe
        -- Writing the coefficient address register must also pulse the strobe.
        -----------------------------------------------------------------------
        report "Test 7: Verifying COEFF_ADDR write generates one-cycle coeff_write_strobe";

        clk_fall;
        reg_write_en <= '1';
        reg_waddr    <= ADDR_COEFF_ADDR;
        reg_wdata    <= x"0000000A";

        clk_rise;
        clk_fall;
        reg_write_en <= '0';

        assert coeff_write_strobe = '1'
            report "FAIL T7: coeff_write_strobe should be '1' on COEFF_ADDR write cycle"
            severity error;
        assert reg_coeff_addr = x"0A"
            report "FAIL T7: reg_coeff_addr should be 0x0A after COEFF_ADDR write"
            severity error;

        -- Reserved bits [31:8] must read back as zero
        clk_fall;
        reg_read_en <= '1';
        reg_raddr   <= ADDR_COEFF_ADDR;
        wait for 1 ns;

        assert reg_rdata(31 downto 8) = (23 downto 0 => '0')
            report "FAIL T7: COEFF_ADDR reserved bits [31:8] must be zero" severity error;

        clk_fall;
        reg_read_en <= '0';

        -- One cycle later: strobe must have dropped
        clk_rise;
        clk_fall;

        assert coeff_write_strobe = '0'
            report "FAIL T7: coeff_write_strobe should be '0' one cycle after COEFF_ADDR write"
            severity error;

        -----------------------------------------------------------------------
        -- Test 8: DATA_IN write generates a one-cycle sample_write_strobe
        -- The strobe must be high for exactly one cycle and reg_data_in must
        -- carry the full 32-bit written value.
        -----------------------------------------------------------------------
        report "Test 8: Verifying DATA_IN write generates one-cycle sample_write_strobe";

        clk_fall;
        reg_write_en <= '1';
        reg_waddr    <= ADDR_DATA_IN;
        reg_wdata    <= x"0000BEEF";

        clk_rise;
        clk_fall;
        reg_write_en <= '0';

        assert sample_write_strobe = '1'
            report "FAIL T8: sample_write_strobe should be '1' on the DATA_IN write cycle"
            severity error;
        assert reg_data_in = x"0000BEEF"
            report "FAIL T8: reg_data_in should be 0x0000BEEF after DATA_IN write"
            severity error;

        -- One cycle later: strobe must have dropped
        clk_rise;
        clk_fall;

        assert sample_write_strobe = '0'
            report "FAIL T8: sample_write_strobe should be '0' one cycle after write"
            severity error;

        -- Verify coeff_write_strobe was NOT asserted (no cross-triggering)
        assert coeff_write_strobe = '0'
            report "FAIL T8: coeff_write_strobe must not be asserted during a DATA_IN write"
            severity error;

        -----------------------------------------------------------------------
        -- Test 9: DATA_OUT is updated by reg_data_out_strobe and is read-only
        -- The DATA_OUT register must update when the FSM pulses
        -- reg_data_out_strobe. A subsequent software write attempt must be
        -- silently ignored.
        -----------------------------------------------------------------------
        report "Test 9: Verifying DATA_OUT updates from FSM strobe and is read-only";

        -- FSM delivers a result
        clk_fall;
        reg_data_out        <= x"0000CAFE";
        reg_data_out_strobe <= '1';

        clk_rise;   -- DATA_OUT register updated
        clk_fall;
        reg_data_out_strobe <= '0';

        -- Read back DATA_OUT
        reg_read_en <= '1';
        reg_raddr   <= ADDR_DATA_OUT;
        wait for 1 ns;

        assert reg_rdata = x"0000CAFE"
            report "FAIL T9: DATA_OUT should be 0x0000CAFE after FSM strobe" severity error;

        clk_fall;
        reg_read_en <= '0';

        -- Attempt software write to DATA_OUT
        reg_write(ADDR_DATA_OUT, x"DEADBEEF");

        -- Read back: must still hold the FSM value
        clk_fall;
        reg_read_en <= '1';
        reg_raddr   <= ADDR_DATA_OUT;
        wait for 1 ns;

        assert reg_rdata = x"0000CAFE"
            report "FAIL T9: DATA_OUT must not be overwritten by a software write"
            severity error;

        clk_fall;
        reg_read_en <= '0';

        -- Verify sample_write_strobe was NOT triggered by the ignored write
        assert sample_write_strobe = '0'
            report "FAIL T9: sample_write_strobe must not fire on a DATA_OUT write attempt"
            severity error;

        -----------------------------------------------------------------------
        -- Test 10: Write priority over simultaneous read
        -- When reg_write_en and reg_read_en are both asserted in the same
        -- cycle, the write must be committed and reg_rdata must return zero
        -- (read suppressed).
        -----------------------------------------------------------------------
        report "Test 10: Verifying write takes priority over simultaneous read";

        -- First establish a known COEFF_DATA value
        reg_write(ADDR_COEFF_DATA, x"00001111");
        clk_rise;

        -- Assert both write and read simultaneously
        clk_fall;
        reg_write_en <= '1';
        reg_waddr    <= ADDR_COEFF_DATA;
        reg_wdata    <= x"00002222";
        reg_read_en  <= '1';
        reg_raddr    <= ADDR_COEFF_DATA;

        wait for 1 ns;  -- combinational read path settles

        -- Read must be suppressed (reg_rdata = 0) when write_en is active
        assert reg_rdata = x"00000000"
            report "FAIL T10: reg_rdata must be zero when write and read are simultaneous (write priority)"
            severity error;

        clk_rise;   -- write is committed on this edge
        clk_fall;
        reg_write_en <= '0';
        reg_read_en  <= '0';

        -- Now read back COEFF_DATA: must reflect the new written value
        clk_fall;
        reg_read_en <= '1';
        reg_raddr   <= ADDR_COEFF_DATA;
        wait for 1 ns;

        assert reg_rdata(15 downto 0) = x"2222"
            report "FAIL T10: COEFF_DATA should be 0x2222 after simultaneous write won priority"
            severity error;

        clk_fall;
        reg_read_en <= '0';

        -----------------------------------------------------------------------
        -- End of simulation
        wait for CLK_PERIOD * 5;
        report "End of simulation";
        wait;

    end process stim_proc;

end architecture tb;
