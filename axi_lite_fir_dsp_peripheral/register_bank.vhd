--------------------------------------------------------------------------------
-- Engineer:    Gabriela Cabrera
--
-- Design:      Register Bank
-- Module:      register_bank
-- Description: Memory-mapped register bank bridging the AXI-Lite slave
--              interface and the DSP control FSM. Implements the following
--              register map:
--
--              0x00  CTRL       [0]     RW  DSP enable
--                               [1]     RW  DSP reset
--                               [3:2]   RW  Mode select
--              0x04  STATUS     [2:0]   RO  {busy, error, ready} (FSM-driven)
--              0x08  COEFF_DATA [15:0]  RW  Coefficient value
--              0x0C  COEFF_ADDR [7:0]   RW  Coefficient index
--              0x10  DATA_IN    [15:0]  RW  DSP input sample
--              0x14  DATA_OUT   [15:0]  RO  DSP output sample (FSM-driven)
--
--              Write operations have priority over read operations to prevent
--              both occurring in the same cycle.
--
--              One-cycle strobes are generated for the DSP control FSM:
--                sample_write_strobe : asserted when DATA_IN is written
--                coeff_write_strobe  : asserted when COEFF_DATA or COEFF_ADDR
--                                      is written
--
--              DATA_OUT is updated when reg_data_out_strobe is asserted by
--              the FSM. STATUS is updated whenever reg_status changes.
-- Date:        09/03/2026
-- Version:     1.0
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity register_bank is
    port (
        -- Clock and reset
        clk   : in  std_logic;
        rst_n : in  std_logic;

        -- AXI-Lite slave interface (from axi_lite_slave_if)
        reg_write_en : in  std_logic;
        reg_read_en  : in  std_logic;
        reg_waddr    : in  std_logic_vector(31 downto 0);
        reg_raddr    : in  std_logic_vector(31 downto 0);
        reg_wdata    : in  std_logic_vector(31 downto 0);
        reg_rdata    : out std_logic_vector(31 downto 0);

        -- Outputs to DSP control FSM
        reg_enable          : out std_logic;
        reg_reset           : out std_logic;
        reg_mode            : out std_logic_vector(1 downto 0);
        reg_coeff_data      : out std_logic_vector(15 downto 0);
        reg_coeff_addr      : out std_logic_vector(7 downto 0);
        reg_data_in         : out std_logic_vector(31 downto 0);
        sample_write_strobe : out std_logic;
        coeff_write_strobe  : out std_logic;

        -- Inputs from DSP control FSM
        reg_status          : in  std_logic_vector(2 downto 0);
        reg_data_out        : in  std_logic_vector(31 downto 0);
        reg_data_out_strobe : in  std_logic
    );
end entity register_bank;

architecture rtl of register_bank is

    -- Register address constants
    constant ADDR_CTRL       : std_logic_vector(31 downto 0) := x"00000000";
    constant ADDR_STATUS     : std_logic_vector(31 downto 0) := x"00000004";
    constant ADDR_COEFF_DATA : std_logic_vector(31 downto 0) := x"00000008";
    constant ADDR_COEFF_ADDR : std_logic_vector(31 downto 0) := x"0000000C";
    constant ADDR_DATA_IN    : std_logic_vector(31 downto 0) := x"00000010";
    constant ADDR_DATA_OUT   : std_logic_vector(31 downto 0) := x"00000014";

    -- Internal register storage
    signal ctrl_reg       : std_logic_vector(31 downto 0) := (others => '0');
    signal status_reg     : std_logic_vector(31 downto 0) := (others => '0');
    signal coeff_data_reg : std_logic_vector(31 downto 0) := (others => '0');
    signal coeff_addr_reg : std_logic_vector(31 downto 0) := (others => '0');
    signal data_in_reg    : std_logic_vector(31 downto 0) := (others => '0');
    signal data_out_reg   : std_logic_vector(31 downto 0) := (others => '0');

    -- Previous STATUS value for change detection
    signal status_last : std_logic_vector(2 downto 0) := (others => '0');

begin

    -- Write process
    -- Handles all synchronous register writes. Write operations have priority
    -- over reads: if reg_write_en is asserted, no read response is generated
    -- in the same cycle (the read process defaults reg_rdata to zeros when
    -- write_en is active).
    -- Generates one-cycle strobes for sample_write_strobe and coeff_write_strobe.
    -- Updates STATUS when a change in reg_status is detected.
    -- Updates DATA_OUT when reg_data_out_strobe is asserted by the FSM.
    p_write : process(clk, rst_n)
    begin
        if rst_n = '0' then
            ctrl_reg            <= (others => '0');
            status_reg          <= (others => '0');
            coeff_data_reg      <= (others => '0');
            coeff_addr_reg      <= (others => '0');
            data_in_reg         <= (others => '0');
            data_out_reg        <= (others => '0');
            status_last         <= (others => '0');
            sample_write_strobe <= '0';
            coeff_write_strobe  <= '0';

        elsif rising_edge(clk) then

            -- Default: deassert single-cycle strobes
            sample_write_strobe <= '0';
            coeff_write_strobe  <= '0';

            -- -----------------------------------------------------------------
            -- STATUS register: updated by the FSM via reg_status.
            -- A change in any bit triggers an update so the register always
            -- reflects the current FSM status.
            status_last <= reg_status;
            if reg_status /= status_last then
                status_reg(2 downto 0) <= reg_status;
                status_reg(31 downto 3) <= (others => '0');
            end if;

            -- -----------------------------------------------------------------
            -- DATA_OUT register: updated when the FSM asserts reg_data_out_strobe,
            -- indicating that a new result has been captured from the DSP.
            if reg_data_out_strobe = '1' then
                data_out_reg <= reg_data_out;
            end if;

            -- -----------------------------------------------------------------
            -- AXI-Lite write path (highest priority)
            -- Write enable gates all software-driven register updates.
            -- Read-only registers (STATUS, DATA_OUT) ignore write attempts.
            if reg_write_en = '1' then
                case reg_waddr is

                    when ADDR_CTRL =>
                        -- RW: bits [3:0] writable, upper bits reserved (forced to 0)
                        ctrl_reg(0)            <= reg_wdata(0);   -- enable
                        ctrl_reg(1)            <= reg_wdata(1);   -- reset
                        ctrl_reg(3 downto 2)   <= reg_wdata(3 downto 2); -- mode
                        ctrl_reg(31 downto 4)  <= (others => '0');

                    when ADDR_COEFF_DATA =>
                        -- RW: bits [15:0] writable, upper bits reserved
                        coeff_data_reg(15 downto 0)  <= reg_wdata(15 downto 0);
                        coeff_data_reg(31 downto 16) <= (others => '0');
                        coeff_write_strobe           <= '1';

                    when ADDR_COEFF_ADDR =>
                        -- RW: bits [7:0] writable, upper bits reserved
                        coeff_addr_reg(7 downto 0)   <= reg_wdata(7 downto 0);
                        coeff_addr_reg(31 downto 8)  <= (others => '0');
                        coeff_write_strobe           <= '1';

                    when ADDR_DATA_IN =>
                        -- RW: full 32-bit data in register
                        data_in_reg         <= reg_wdata;
                        sample_write_strobe <= '1';

                    when ADDR_STATUS | ADDR_DATA_OUT =>
                        -- RO registers: writes silently ignored
                        null;

                    when others =>
                        null;

                end case;
            end if;

        end if;
    end process p_write;

    -- Read process
    -- Drives reg_rdata combinationally based on reg_raddr.
    -- Suppressed (outputs zero) when reg_write_en is active to enforce
    -- write-over-read priority.
    p_read : process(all)
    begin
        reg_rdata <= (others => '0');

        -- Write takes priority: suppress read output in the same cycle
        if reg_read_en = '1' and reg_write_en = '0' then
            case reg_raddr is
                when ADDR_CTRL       => reg_rdata <= ctrl_reg;
                when ADDR_STATUS     => reg_rdata <= status_reg;
                when ADDR_COEFF_DATA => reg_rdata <= coeff_data_reg;
                when ADDR_COEFF_ADDR => reg_rdata <= coeff_addr_reg;
                when ADDR_DATA_IN    => reg_rdata <= data_in_reg;
                when ADDR_DATA_OUT   => reg_rdata <= data_out_reg;
                when others          => reg_rdata <= (others => '0');
            end case;
        end if;
    end process p_read;

    -- Output assignments to DSP control FSM
    -- Fields are extracted from their respective registers.
    reg_enable     <= ctrl_reg(0);
    reg_reset      <= ctrl_reg(1);
    reg_mode       <= ctrl_reg(3 downto 2);
    reg_coeff_data <= coeff_data_reg(15 downto 0);
    reg_coeff_addr <= coeff_addr_reg(7 downto 0);
    reg_data_in    <= data_in_reg;

end architecture rtl;
