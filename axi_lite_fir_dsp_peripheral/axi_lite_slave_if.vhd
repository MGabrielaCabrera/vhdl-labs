--------------------------------------------------------------------------------
-- Engineer:    Gabriela Cabrera
-- 
-- Design:     AXI-Lite Slave Interface
-- Module:      axi_lite_slave_if
-- Description: The AXI-Lite slave interface implements the full protocol required
--              for communication with the processor, including independent read and
--              write channels and VALID/READY handshake signaling. It decodes incoming
--              transactions and converts them into simplified internal control signals
--              such as read enable, write enable, address, and data buses. By isolating
--              bus protocol handling in a dedicated block, the rest of the system remains
--              independent of timing and signaling details specific to the AXI standard.
-- Date:        04/03/2026
-- Version:     1.0
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity axi_lite_slave_if is
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

        -- Internal control signals
        reg_write_en : out std_logic; -- Signal to enable register write
        reg_read_en : out std_logic; -- Signal to enable register read
        reg_waddr : out std_logic_vector(31 downto 0); -- Address bus for register access
        reg_raddr : out std_logic_vector(31 downto 0); -- Address bus for register access
        reg_wdata : out std_logic_vector(31 downto 0); -- Data bus for register write
        reg_rdata : in std_logic_vector(31 downto 0) -- Data bus for register read
    );
end axi_lite_slave_if;

architecture rtl of axi_lite_slave_if is

    -- Write FSM
    -- IDLE      : waiting for AW and W channels
    -- AW_WAIT   : write address received, waiting for write data
    -- W_WAIT    : write data received, waiting for write address
    -- EXEC      : both received, performing write, asserting BVALID
    -- BRESP     : waiting for BREADY handshake
    type t_write_state is (IDLE, AW_WAIT, W_WAIT, EXEC, BRESP);
    signal write_state : t_write_state := IDLE;

    -- Read FSM
    -- IDLE      : waiting for AR channel
    -- EXEC      : address captured, one cycle for register read latency
    -- RRESP     : asserting RVALID, waiting for RREADY handshake
    type t_read_state is (IDLE, EXEC, RRESP);
    signal read_state : t_read_state := IDLE;

    -- Internal registers to hold captured transaction data
    signal reg_awaddr_int : std_logic_vector(31 downto 0) := (others => '0');
    signal reg_wdata_int  : std_logic_vector(31 downto 0) := (others => '0');
    signal reg_araddr_int : std_logic_vector(31 downto 0) := (others => '0');

    -- Registered error flags
    signal write_error_lat : std_logic := '0';
    signal read_error_lat  : std_logic := '0';

    -- Combinational strobed-write data
    signal axi_wdata_strb : std_logic_vector(31 downto 0);

    -- Address validation helpers
    function addr_valid(addr : std_logic_vector(31 downto 0)) return std_logic is
    begin
        case addr(5 downto 2) is
            when "0000" | "0001" | "0010" | "0011" | "0100" | "0101" => return '1';
            when others => return '0';
        end case;
    end function;

    function addr_misaligned(addr : std_logic_vector(31 downto 0)) return std_logic is
    begin
        if addr(1 downto 0) /= "00" then
            return '1';
        else
            return '0';
        end if;
    end function;

begin

    -- Write strobe: apply byte enables combinationally on incoming bus
    -- The result is registered when W channel is accepted
    p_wstrb : process(s_axi_wstrb, s_axi_wdata)
    begin
        axi_wdata_strb <= (others => '0');
        for i in 0 to 3 loop
            if s_axi_wstrb(i) = '1' then
                axi_wdata_strb((i*8)+7 downto i*8) <= s_axi_wdata((i*8)+7 downto i*8);
            end if;
        end loop;
    end process p_wstrb;

    -- Write FSM
    p_write_fsm : process(clk, rst_n)
    begin
        if rst_n = '0' then
            write_state     <= IDLE;
            reg_awaddr_int  <= (others => '0');
            reg_wdata_int   <= (others => '0');
            write_error_lat <= '0';
            reg_write_en    <= '0';
            reg_waddr       <= (others => '0');
            reg_wdata       <= (others => '0');
            s_axi_awready   <= '1';
            s_axi_wready    <= '1';
            s_axi_bvalid    <= '0';
            s_axi_bresp     <= "00";

        elsif rising_edge(clk) then

            -- Default: deassert single-cycle strobes
            reg_write_en <= '0';

            case write_state is
                -- -------------------------------------------------------
                when IDLE =>
                    s_axi_awready <= '1';
                    s_axi_wready  <= '1';
                    s_axi_bvalid  <= '0';

                    if s_axi_awvalid = '1' and s_axi_wvalid = '1' then
                        -- Both channels presented simultaneously
                        reg_awaddr_int  <= s_axi_awaddr;
                        reg_wdata_int   <= axi_wdata_strb;
                        write_error_lat <= addr_misaligned(s_axi_awaddr) or
                                           not addr_valid(s_axi_awaddr);
                        s_axi_awready   <= '0';
                        s_axi_wready    <= '0';
                        write_state     <= EXEC;

                    elsif s_axi_awvalid = '1' then
                        -- Only address presented
                        reg_awaddr_int  <= s_axi_awaddr;
                        write_error_lat <= addr_misaligned(s_axi_awaddr) or
                                           not addr_valid(s_axi_awaddr);
                        s_axi_awready   <= '0';
                        write_state     <= AW_WAIT;

                    elsif s_axi_wvalid = '1' then
                        -- Only data presented
                        reg_wdata_int <= axi_wdata_strb;
                        s_axi_wready  <= '0';
                        write_state   <= W_WAIT;
                    end if;

                -- -------------------------------------------------------
                -- Address received first, waiting for data
                when AW_WAIT =>
                    s_axi_wready <= '1';
                    if s_axi_wvalid = '1' then
                        reg_wdata_int <= axi_wdata_strb;
                        s_axi_wready  <= '0';
                        write_state   <= EXEC;
                    end if;

                -- -------------------------------------------------------
                -- Data received first, waiting for address
                when W_WAIT =>
                    s_axi_awready <= '1';
                    if s_axi_awvalid = '1' then
                        reg_awaddr_int  <= s_axi_awaddr;
                        write_error_lat <= addr_misaligned(s_axi_awaddr) or
                                           not addr_valid(s_axi_awaddr);
                        s_axi_awready   <= '0';
                        write_state     <= EXEC;
                    end if;

                -- -------------------------------------------------------
                -- Perform the write and assert BVALID
                when EXEC =>
                    if write_error_lat = '0' then
                        reg_write_en <= '1';           -- single-cycle write pulse
                        reg_waddr    <= reg_awaddr_int;
                        reg_wdata    <= reg_wdata_int;
                        s_axi_bresp  <= "00";          -- OKAY
                    else
                        s_axi_bresp  <= "10";          -- SLVERR
                    end if;
                    s_axi_bvalid <= '1';
                    write_state  <= BRESP;

                -- -------------------------------------------------------
                -- Wait for master to accept the write response
                when BRESP =>
                    if s_axi_bready = '1' then
                        s_axi_bvalid <= '0';
                        write_state  <= IDLE;
                    end if;

                when others =>
                    write_state <= IDLE;

            end case;
        end if;
    end process p_write_fsm;

    -- Read FSM
    p_read_fsm : process(clk, rst_n)
    begin
        if rst_n = '0' then
            read_state     <= IDLE;
            reg_araddr_int <= (others => '0');
            read_error_lat <= '0';
            reg_read_en    <= '0';
            reg_raddr      <= (others => '0');
            s_axi_arready  <= '1';
            s_axi_rvalid   <= '0';
            s_axi_rdata    <= (others => '0');
            s_axi_rresp    <= "00";

        elsif rising_edge(clk) then

            -- Default: deassert single-cycle strobes
            reg_read_en <= '0';

            case read_state is
                -- -------------------------------------------------------
                when IDLE =>
                    s_axi_arready <= '1';
                    s_axi_rvalid  <= '0';

                    if s_axi_arvalid = '1' then
                        reg_araddr_int <= s_axi_araddr;
                        read_error_lat <= addr_misaligned(s_axi_araddr) or
                                          not addr_valid(s_axi_araddr);
                        s_axi_arready  <= '0';
                        read_state     <= EXEC;
                    end if;

                -- -------------------------------------------------------
                -- Assert read enable for one cycle so the register
                -- can provide data; capture result on the next cycle
                when EXEC =>
                    if read_error_lat = '0' then
                        reg_read_en  <= '1';
                        reg_raddr    <= reg_araddr_int;
                        s_axi_rresp  <= "00";           -- OKAY
                    else
                        s_axi_rresp  <= "10";           -- SLVERR
                    end if;
                    -- Sample register data, 1-cycle read latency
                    s_axi_rdata  <= reg_rdata;
                    s_axi_rvalid <= '1';
                    read_state   <= RRESP;

                -- -------------------------------------------------------
                -- Hold RVALID/RDATA until master asserts RREADY
                when RRESP =>
                    -- Keep read data stable
                    if s_axi_rready = '1' then
                        s_axi_rvalid <= '0';
                        read_state   <= IDLE;
                    end if;

                when others =>
                    read_state <= IDLE;

            end case;
        end if;
    end process p_read_fsm;

end architecture rtl;