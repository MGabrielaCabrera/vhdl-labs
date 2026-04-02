--------------------------------------------------------------------------------
-- Engineer:    Gabriela Cabrera
--
-- Design:      Testbench - Top Level Wrapper
-- Module:      top_level_wrapper_tb
-- Description: Integration testbench exercising the full signal path through
--              the AXI-Lite slave interface, register bank and control FSM.
--              All interactions use the AXI-Lite protocol exactly as an
--              external master would.
--
--              Tests:
--                T1  - Reset state: all AXI outputs at safe defaults
--                T2  - AXI write to CTRL and readback (enable, reset, mode)
--                T3  - CTRL reserved bits forced to zero
--                T4  - AXI write to CTRL enables DSP (dsp_enable asserted)
--                T5  - AXI write to STATUS is silently ignored (RO register)
--                T6  - AXI write to COEFF_DATA, coeff_write_strobe, dsp_coeff signals
--                T7  - AXI write to COEFF_ADDR, coeff_write_strobe, dsp_coeff_addr
--                T8  - AXI write to DATA_IN triggers sample_write_strobe and
--                      DSP SEND handshake (dsp_data_in_valid, dsp_data_in)
--                T9  - DSP result captured: DATA_OUT readable via AXI after
--                      dsp_data_out_valid, dsp_data_out_ready pulsed one cycle
--                T10 - Full write-then-read round trip for COEFF_DATA
--                T11 - AXI write response BRESP=OKAY for valid address
--                T12 - AXI write response BRESP=SLVERR for out-of-range address
--                T13 - AXI read response RRESP=SLVERR for out-of-range address
--                T14 - DSP stays in WAIT_RESULT until dsp_data_out_valid;
--                      STATUS.BUSY held across multiple cycles
-- Date:        16/03/2026
-- Version:     1.0
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top_level_wrapper_tb is
end entity top_level_wrapper_tb;

architecture tb of top_level_wrapper_tb is

    constant CLK_PERIOD : time := 10 ns;

    -- Clock / reset
    signal clk   : std_logic := '0';
    signal rst_n : std_logic := '0';

    -- AXI-Lite write address channel
    signal s_axi_awaddr  : std_logic_vector(31 downto 0) := (others => '0');
    signal s_axi_awvalid : std_logic := '0';
    signal s_axi_awready : std_logic;

    -- AXI-Lite write data channel
    signal s_axi_wdata  : std_logic_vector(31 downto 0) := (others => '0');
    signal s_axi_wvalid : std_logic := '0';
    signal s_axi_wready : std_logic;
    signal s_axi_wstrb  : std_logic_vector(3 downto 0) := "1111";

    -- AXI-Lite write response channel
    signal s_axi_bresp  : std_logic_vector(1 downto 0);
    signal s_axi_bvalid : std_logic;
    signal s_axi_bready : std_logic := '0';

    -- AXI-Lite read address channel
    signal s_axi_araddr  : std_logic_vector(31 downto 0) := (others => '0');
    signal s_axi_arvalid : std_logic := '0';
    signal s_axi_arready : std_logic;

    -- AXI-Lite read data channel
    signal s_axi_rdata  : std_logic_vector(31 downto 0);
    signal s_axi_rresp  : std_logic_vector(1 downto 0);
    signal s_axi_rvalid : std_logic;
    signal s_axi_rready : std_logic := '0';

    -- External DSP interface
    signal dsp_enable          : std_logic;
    signal dsp_reset           : std_logic;
    signal dsp_mode            : std_logic_vector(1 downto 0);
    signal dsp_data_in         : std_logic_vector(31 downto 0);
    signal dsp_data_in_valid   : std_logic;
    signal dsp_data_in_ready   : std_logic := '0';
    signal dsp_data_out        : std_logic_vector(31 downto 0) := (others => '0');
    signal dsp_data_out_valid  : std_logic := '0';
    signal dsp_data_out_ready  : std_logic;
    signal dsp_coeff_data      : std_logic_vector(31 downto 0);
    signal dsp_coeff_addr      : std_logic_vector(7 downto 0);
    signal dsp_coeff_we        : std_logic;

    -- Register address constants
    constant ADDR_CTRL       : std_logic_vector(31 downto 0) := x"00000000";
    constant ADDR_STATUS     : std_logic_vector(31 downto 0) := x"00000004";
    constant ADDR_COEFF_DATA : std_logic_vector(31 downto 0) := x"00000008";
    constant ADDR_COEFF_ADDR : std_logic_vector(31 downto 0) := x"0000000C";
    constant ADDR_DATA_IN    : std_logic_vector(31 downto 0) := x"00000010";
    constant ADDR_DATA_OUT   : std_logic_vector(31 downto 0) := x"00000014";
    constant ADDR_OOB        : std_logic_vector(31 downto 0) := x"00000040"; -- out of range

    component top_level_wrapper is
        port (
            clk               : in  std_logic;
            rst_n             : in  std_logic;
            s_axi_awaddr      : in  std_logic_vector(31 downto 0);
            s_axi_awvalid     : in  std_logic;
            s_axi_awready     : out std_logic;
            s_axi_wdata       : in  std_logic_vector(31 downto 0);
            s_axi_wvalid      : in  std_logic;
            s_axi_wready      : out std_logic;
            s_axi_wstrb       : in  std_logic_vector(3 downto 0);
            s_axi_bresp       : out std_logic_vector(1 downto 0);
            s_axi_bvalid      : out std_logic;
            s_axi_bready      : in  std_logic;
            s_axi_araddr      : in  std_logic_vector(31 downto 0);
            s_axi_arvalid     : in  std_logic;
            s_axi_arready     : out std_logic;
            s_axi_rdata       : out std_logic_vector(31 downto 0);
            s_axi_rresp       : out std_logic_vector(1 downto 0);
            s_axi_rvalid      : out std_logic;
            s_axi_rready      : in  std_logic;
            dsp_enable        : out std_logic;
            dsp_reset         : out std_logic;
            dsp_mode          : out std_logic_vector(1 downto 0);
            dsp_data_in       : out std_logic_vector(31 downto 0);
            dsp_data_in_valid : out std_logic;
            dsp_data_in_ready : in  std_logic;
            dsp_data_out      : in  std_logic_vector(31 downto 0);
            dsp_data_out_valid: in  std_logic;
            dsp_data_out_ready: out std_logic;
            dsp_coeff_data    : out std_logic_vector(31 downto 0);
            dsp_coeff_addr    : out std_logic_vector(7 downto 0);
            dsp_coeff_we      : out std_logic
        );
    end component top_level_wrapper;

begin

	-- Clock generation
	clk_process : process
	begin
		while now < 2500 ns loop
			clk <= '1'; wait for CLK_PERIOD/2;
			clk <= '0'; wait for CLK_PERIOD/2;
		end loop;
		wait;
	end process;

    dut : top_level_wrapper
        port map (
            clk                => clk,
            rst_n              => rst_n,
            s_axi_awaddr       => s_axi_awaddr,
            s_axi_awvalid      => s_axi_awvalid,
            s_axi_awready      => s_axi_awready,
            s_axi_wdata        => s_axi_wdata,
            s_axi_wvalid       => s_axi_wvalid,
            s_axi_wready       => s_axi_wready,
            s_axi_wstrb        => s_axi_wstrb,
            s_axi_bresp        => s_axi_bresp,
            s_axi_bvalid       => s_axi_bvalid,
            s_axi_bready       => s_axi_bready,
            s_axi_araddr       => s_axi_araddr,
            s_axi_arvalid      => s_axi_arvalid,
            s_axi_arready      => s_axi_arready,
            s_axi_rdata        => s_axi_rdata,
            s_axi_rresp        => s_axi_rresp,
            s_axi_rvalid       => s_axi_rvalid,
            s_axi_rready       => s_axi_rready,
            dsp_enable         => dsp_enable,
            dsp_reset          => dsp_reset,
            dsp_mode           => dsp_mode,
            dsp_data_in        => dsp_data_in,
            dsp_data_in_valid  => dsp_data_in_valid,
            dsp_data_in_ready  => dsp_data_in_ready,
            dsp_data_out       => dsp_data_out,
            dsp_data_out_valid => dsp_data_out_valid,
            dsp_data_out_ready => dsp_data_out_ready,
            dsp_coeff_data     => dsp_coeff_data,
            dsp_coeff_addr     => dsp_coeff_addr,
            dsp_coeff_we       => dsp_coeff_we
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

        -- ----------------------------------------------------------------
        -- Full AXI-Lite write: present AW and W simultaneously, wait for
        -- BVALID, assert BREADY, return BRESP value via a variable.
        -- ----------------------------------------------------------------
        procedure axi_write (
            addr : in  std_logic_vector(31 downto 0);
            data : in  std_logic_vector(31 downto 0);
            strb : in  std_logic_vector(3 downto 0) := "1111"
        ) is
        begin
            clk_fall;
            s_axi_awaddr  <= addr;
            s_axi_awvalid <= '1';
            s_axi_wdata   <= data;
            s_axi_wvalid  <= '1';
            s_axi_wstrb   <= strb;

            -- Wait for both ready signals
            loop
                clk_rise;
                exit when s_axi_awready = '1' and s_axi_wready = '1';
            end loop;

            -- Deassert valids mid-cycle
            wait for CLK_PERIOD / 2;
            s_axi_awvalid <= '0';
            s_axi_wvalid  <= '0';

            -- Wait for write response
            loop
                clk_rise;
                exit when s_axi_bvalid = '1';
            end loop;

            -- Accept the response
            s_axi_bready <= '1';
            clk_rise;
            s_axi_bready <= '0';
        end procedure;

        -- ----------------------------------------------------------------
        -- Full AXI-Lite read: present AR, wait for RVALID, accept with
        -- RREADY. Read data available on s_axi_rdata after procedure.
        -- ----------------------------------------------------------------
        procedure axi_read (
            addr : in std_logic_vector(31 downto 0)
        ) is
        begin
            clk_fall;
            s_axi_araddr  <= addr;
            s_axi_arvalid <= '1';

            loop
                clk_rise;
                exit when s_axi_arready = '1';
            end loop;

            --wait for CLK_PERIOD / 2;
            s_axi_arvalid <= '0';

            loop
                clk_rise;
                exit when s_axi_rvalid = '1';
            end loop;

            -- Sample rdata here --> caller reads s_axi_rdata after procedure
            wait for CLK_PERIOD / 2;
            s_axi_rready <= '1';
            clk_rise;
            wait for CLK_PERIOD / 2;
            s_axi_rready <= '0';
        end procedure;

    begin

        -----------------------------------------------------------------------
        -- Test 1: Reset state
        -- All AXI output signals must be at their safe defaults while
        -- rst_n is held low.
        -----------------------------------------------------------------------
        report "Test 1: Verifying AXI output reset state";

        rst_n          <= '0';
        s_axi_awvalid  <= '0';
        s_axi_wvalid   <= '0';
        s_axi_bready   <= '0';
        s_axi_arvalid  <= '0';
        s_axi_rready   <= '0';
        dsp_data_in_ready  <= '0';
        dsp_data_out_valid <= '0';
        dsp_data_out       <= (others => '0');

        clk_rise; clk_rise; clk_rise;
        clk_fall;

        assert s_axi_bvalid       = '0'
            report "FAIL T1: s_axi_bvalid should be '0' in reset"       severity error;
        assert s_axi_rvalid       = '0'
            report "FAIL T1: s_axi_rvalid should be '0' in reset"       severity error;
        assert dsp_enable         = '0'
            report "FAIL T1: dsp_enable should be '0' in reset"         severity error;
        assert dsp_reset          = '0'
            report "FAIL T1: dsp_reset should be '0' in reset"          severity error;
        assert dsp_data_in_valid  = '0'
            report "FAIL T1: dsp_data_in_valid should be '0' in reset"  severity error;
        assert dsp_data_out_ready = '0'
            report "FAIL T1: dsp_data_out_ready should be '0' in reset" severity error;
        assert dsp_coeff_we       = '0'
            report "FAIL T1: dsp_coeff_we should be '0' in reset"       severity error;

        clk_fall;
        rst_n <= '1';
        clk_rise; clk_rise;

        -----------------------------------------------------------------------
        -- Test 2: AXI write to CTRL and readback
        -- Writing enable=1, reset=1, mode="10" via AXI must reach the DSP
        -- outputs and be readable back at address 0x00.
        -- CTRL encoding: bit0=enable, bit1=reset, bit3:2=mode --> 0x0B
        -----------------------------------------------------------------------
        report "Test 2: Verifying AXI write to CTRL and readback";

        axi_write(ADDR_CTRL, x"0000000B");

        clk_fall;
        assert dsp_enable = '1'
            report "FAIL T2: dsp_enable should be '1' after CTRL write" severity error;
        assert dsp_reset  = '1'
            report "FAIL T2: dsp_reset should be '1' after CTRL write"  severity error;
        assert dsp_mode   = "10"
            report "FAIL T2: dsp_mode should be 10 after CTRL write"    severity error;

        axi_read(ADDR_CTRL);
        clk_fall;

        assert s_axi_rdata(0)          = '1'
            report "FAIL T2: CTRL readback bit0 (enable) should be '1'"   severity error;
        assert s_axi_rdata(1)          = '1'
            report "FAIL T2: CTRL readback bit1 (reset) should be '1'"    severity error;
        assert s_axi_rdata(3 downto 2) = "10"
            report "FAIL T2: CTRL readback bits[3:2] (mode) should be 10" severity error;

        -- Restore CTRL
        axi_write(ADDR_CTRL, x"00000000");

        -----------------------------------------------------------------------
        -- Test 3: CTRL reserved bits are forced to zero
        -- Writing 0xFFFFFFFF to CTRL must only store bits [3:0]; all upper
        -- bits must read back as zero through the full AXI path.
        -----------------------------------------------------------------------
        report "Test 3: Verifying CTRL reserved bits are forced to zero";

        axi_write(ADDR_CTRL, x"FFFFFFFF");
        axi_read(ADDR_CTRL);
        clk_fall;

        assert s_axi_rdata(31 downto 4) = (27 downto 0 => '0')
            report "FAIL T3: CTRL reserved bits [31:4] must read as zero" severity error;
        assert s_axi_rdata(3 downto 0)  = "1111"
            report "FAIL T3: CTRL writable bits [3:0] should all be '1'" severity error;

        -- Restore
        axi_write(ADDR_CTRL, x"00000000");
        clk_rise;

        -----------------------------------------------------------------------
        -- Test 4: AXI write to CTRL enables DSP (dsp_enable propagation)
        -- Verifies that writing bit 0 of CTRL makes dsp_enable go high, and
        -- clearing it makes it go low again.
        -----------------------------------------------------------------------
        report "Test 4: Verifying CTRL enable bit propagates to dsp_enable";

        axi_write(ADDR_CTRL, x"00000001");  -- enable=1 only
        clk_fall;

        assert dsp_enable = '1'
            report "FAIL T4: dsp_enable should be '1' after writing CTRL[0]=1" severity error;
        assert dsp_reset  = '0'
            report "FAIL T4: dsp_reset should remain '0'"                       severity error;
        assert dsp_mode   = "00"
            report "FAIL T4: dsp_mode should remain 00"                         severity error;

        axi_write(ADDR_CTRL, x"00000000");  -- clear enable
        clk_fall;

        assert dsp_enable = '0'
            report "FAIL T4: dsp_enable should be '0' after clearing CTRL[0]"  severity error;

        -----------------------------------------------------------------------
        -- T5: AXI write to STATUS is silently ignored (RO register)
        -- STATUS must not change as a result of a software AXI write.
        -- The response must still be OKAY (write accepted by AXI slave).
        -----------------------------------------------------------------------
        report "Test 5: Verifying STATUS is read-only (AXI write ignored)";

        -- Read STATUS before attempted write to establish baseline
        axi_read(ADDR_STATUS);
        clk_fall;
        -- baseline is all zeros (FSM in IDLE, ready bit depends on STATUS logic)

        -- Attempt to overwrite STATUS
        axi_write(ADDR_STATUS, x"FFFFFFFF");

        -- Read back: reserved bits must remain zero
        axi_read(ADDR_STATUS);
        clk_fall;

        assert s_axi_rdata(31 downto 3) = (28 downto 0 => '0')
            report "FAIL T5: STATUS reserved bits must be zero after write attempt" severity error;
        -- The AXI transaction itself must have completed with OKAY
        assert s_axi_bresp = "00"
            report "FAIL T5: BRESP should be OKAY even for a write to a RO register"
            severity error;

        -----------------------------------------------------------------------
        -- Test 6: AXI write to COEFF_DATA propagates to dsp_coeff_data and
        --     generates a one-cycle dsp_coeff_we pulse
        -- DSP must be disabled (CTRL.ENABLE=0) for coeff_write_strobe to fire.
        -----------------------------------------------------------------------
        report "Test 6 START: Verifying COEFF_DATA write propagates to DSP coefficient interface";

        -- Ensure DSP is disabled
        axi_write(ADDR_CTRL, x"00000000");

        -- Write coefficient data
        axi_write(ADDR_COEFF_DATA, x"00001234");

        --clk_fall;

        assert dsp_coeff_data(15 downto 0) = x"1234"
            report "FAIL T6: dsp_coeff_data[15:0] should be 0x1234" severity error;
        assert dsp_coeff_we = '1'
            report "FAIL T6: dsp_coeff_we should be '1' during LOAD_COEFF state" severity error;

        -- One cycle later: dsp_coeff_we must deassert
        clk_rise;
        clk_fall;

        assert dsp_coeff_we = '0'
            report "FAIL T6: dsp_coeff_we should be '0' after LOAD_COEFF completes" severity error;

        -----------------------------------------------------------------------
        -- Test 7: AXI write to COEFF_ADDR propagates to dsp_coeff_addr and
        --     also generates a one-cycle dsp_coeff_we pulse
        -----------------------------------------------------------------------
        report "Test 7: Verifying COEFF_ADDR write propagates to dsp_coeff_addr";

        axi_write(ADDR_COEFF_ADDR, x"0000000F");

        -- clk_fall;

        assert dsp_coeff_addr = x"0F"
            report "FAIL T7: dsp_coeff_addr should be 0x0F"                      severity error;
        assert dsp_coeff_we   = '1'
            report "FAIL T7: dsp_coeff_we should be '1' during LOAD_COEFF state" severity error;

        clk_rise;
        clk_fall;

        assert dsp_coeff_we = '0'
            report "FAIL T7: dsp_coeff_we should be '0' after one cycle"  severity error;

        -----------------------------------------------------------------------
        -- Test 8: AXI write to DATA_IN triggers DSP SEND handshake
        -- When CTRL.ENABLE=1 and DATA_IN is written, dsp_data_in_valid must
        -- be asserted and the correct sample must appear on dsp_data_in.
        -- FSM must hold dsp_data_in_valid until dsp_data_in_ready is seen.
        -----------------------------------------------------------------------
        report "Test 8: Verifying DATA_IN write triggers DSP sample send";

        -- Enable DSP
        axi_write(ADDR_CTRL, x"00000001");

        -- Write a sample to DATA_IN
        axi_write(ADDR_DATA_IN, x"0000BEEF");

        -- After the write completes and the FSM has entered SEND, check outputs
        clk_fall;

        assert dsp_data_in_valid     = '1'
            report "FAIL T8: dsp_data_in_valid should be '1' in SEND state"    severity error;
        assert dsp_data_in(15 downto 0) = x"BEEF"
            report "FAIL T8: dsp_data_in[15:0] should be 0xBEEF"               severity error;

        -- Simulate DSP accepting data after a couple of cycles
        clk_rise; clk_fall;

        assert dsp_data_in_valid = '1'
            report "FAIL T8: dsp_data_in_valid must remain '1' while waiting for ready"
            severity error;

        -- DSP asserts ready
        dsp_data_in_ready <= '1';
        clk_rise;
        clk_fall;
        dsp_data_in_ready <= '0';

        assert dsp_data_in_valid = '0'
            report "FAIL T8: dsp_data_in_valid should be '0' after handshake"  severity error;

        -----------------------------------------------------------------------
        -- Test 9: DSP result captured in DATA_OUT register and readable via AXI
        -- After the DSP asserts dsp_data_out_valid, the result must be stored
        -- in DATA_OUT, dsp_data_out_ready must pulse for exactly one cycle,
        -- and the value must be readable through AXI at address 0x14.
        -----------------------------------------------------------------------
        report "Test 9: Verifying DSP result captured and readable via AXI";

        -- DSP is currently in WAIT_RESULT; deliver a result
        clk_fall;
        dsp_data_out       <= x"00001234";
        dsp_data_out_valid <= '1';

        clk_rise;
        clk_fall;
        dsp_data_out_valid <= '0';

        -- dsp_data_out_ready must be pulsed for exactly one cycle
        assert dsp_data_out_ready = '1'
            report "FAIL T9: dsp_data_out_ready should be '1' on result capture cycle"
            severity error;

        clk_rise;
        clk_fall;

        assert dsp_data_out_ready = '0'
            report "FAIL T9: dsp_data_out_ready should be '0' one cycle after capture"
            severity error;

        -- Read DATA_OUT via AXI
        axi_read(ADDR_DATA_OUT);
        clk_fall;

        assert s_axi_rdata(15 downto 0) = x"1234"
            report "FAIL T9: DATA_OUT readback should be 0x1234 via AXI"   severity error;
        assert s_axi_rresp = "00"
            report "FAIL T9: RRESP should be OKAY for DATA_OUT read"        severity error;

        -- Disable DSP before next tests
        axi_write(ADDR_CTRL, x"00000000");
        clk_rise; clk_rise;

        -----------------------------------------------------------------------
        -- Test 10: Full write-then-read round trip for COEFF_DATA
        -- Verifies the complete AXI write --> register bank --> AXI read path
        -- for a coefficient value, confirming data integrity end-to-end.
        -----------------------------------------------------------------------
        report "Test 10: Verifying full write/read round trip for COEFF_DATA";

        axi_write(ADDR_COEFF_DATA, x"0000ABCD");
        axi_read(ADDR_COEFF_DATA);
        clk_fall;

        assert s_axi_rdata(15 downto 0) = x"ABCD"
            report "FAIL T10: COEFF_DATA readback should be 0xABCD"        severity error;
        assert s_axi_rdata(31 downto 16) = x"0000"
            report "FAIL T10: COEFF_DATA reserved bits [31:16] must be zero" severity error;
        assert s_axi_rresp = "00"
            report "FAIL T10: RRESP should be OKAY for COEFF_DATA read"    severity error;

        -----------------------------------------------------------------------
        -- Test 11: AXI write response BRESP = OKAY for a valid address
        -- A write to any valid, word-aligned address must complete with
        -- BRESP = "00" (OKAY).
        -----------------------------------------------------------------------
        report "Test 11: Verifying BRESP=OKAY for valid AXI write";

        axi_write(ADDR_CTRL, x"00000000");
        clk_fall;

        assert s_axi_bresp = "00"
            report "FAIL T11: BRESP should be OKAY (00) for write to valid address"
            severity error;

        -----------------------------------------------------------------------
        -- T12: AXI write response BRESP = SLVERR for out-of-range address
        -- A write to an address outside the register map must return
        -- BRESP = "10" (SLVERR).
        -----------------------------------------------------------------------
        report "Test 12: Verifying BRESP=SLVERR for out-of-range AXI write";

        axi_write(ADDR_OOB, x"DEADBEEF");
        clk_fall;

        assert s_axi_bresp = "10"
            report "FAIL T12: BRESP should be SLVERR (10) for out-of-range write"
            severity error;

        -----------------------------------------------------------------------
        -- Test 13: AXI read response RRESP = SLVERR for out-of-range address
        -- A read from an address outside the register map must return
        -- RRESP = "10" (SLVERR) and RDATA = 0x00000000.
        -----------------------------------------------------------------------
        report "Test 13: Verifying RRESP=SLVERR for out-of-range AXI read";

        axi_read(ADDR_OOB);
        clk_fall;

        assert s_axi_rresp = "10"
            report "FAIL T13: RRESP should be SLVERR (10) for out-of-range read"
            severity error;
        assert s_axi_rdata = x"00000000"
            report "FAIL T13: RDATA should be 0x00000000 for out-of-range read"
            severity error;


        -----------------------------------------------------------------------
        -- Test 14: STATUS.BUSY held across multiple cycles in WAIT_RESULT
        -- After sending a sample (DATA_IN write with ENABLE=1) and completing
        -- the dsp_data_in handshake, the FSM must remain in WAIT_RESULT with
        -- STATUS.BUSY asserted for multiple cycles until dsp_data_out_valid.
        -----------------------------------------------------------------------
        report "Test 14: Verifying STATUS.BUSY held in WAIT_RESULT until result arrives";

        -- Enable DSP and send a sample
        axi_write(ADDR_CTRL,    x"00000001");
        axi_write(ADDR_DATA_IN, x"00005A5A");

        -- Complete the data-in handshake immediately
        clk_fall;
        dsp_data_in_ready <= '1';
        clk_rise;
        clk_fall;
        dsp_data_in_ready <= '0';

        -- FSM is now in WAIT_RESULT; read STATUS over 4 consecutive cycles
        for cycle in 1 to 4 loop
            axi_read(ADDR_STATUS);
            clk_fall;
            assert s_axi_rdata(2) = '1'
                report "FAIL T15: STATUS.BUSY (bit2) should be '1' in WAIT_RESULT, cycle "
                       & integer'image(cycle) severity error;
            assert s_axi_rdata(0) = '0'
                report "FAIL T15: STATUS.READY (bit0) should be '0' while busy, cycle "
                       & integer'image(cycle) severity error;
        end loop;

        -- Deliver result to exit WAIT_RESULT
        clk_fall;
        dsp_data_out       <= x"00005A5A";
        dsp_data_out_valid <= '1';
        clk_rise;
        clk_fall;
        dsp_data_out_valid <= '0';
        clk_rise; clk_rise;

        -- STATUS should now show ready
        axi_read(ADDR_STATUS);
        clk_fall;

        assert s_axi_rdata(2) = '0'
            report "FAIL T15: STATUS.BUSY should be '0' after result captured"  severity error;
        assert s_axi_rdata(0) = '1'
            report "FAIL T15: STATUS.READY should be '1' after result captured" severity error;

        -----------------------------------------------------------------------
        -- End of simulation
        -----------------------------------------------------------------------
        wait for CLK_PERIOD * 10;
        report "End of simulation" severity note;
        wait;

    end process stim_proc;

end architecture tb;
