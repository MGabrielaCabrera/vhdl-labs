library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity axi_lite_slave_if_tb is
end entity axi_lite_slave_if_tb;

architecture tb of axi_lite_slave_if_tb is

    constant CLK_PERIOD : time := 10 ns;

    -- Clock and reset
    signal clk   : std_logic := '0';
    signal rst_n : std_logic := '0';

    -- AXI-Lite Write Address channel
    signal s_axi_awaddr  : std_logic_vector(31 downto 0) := (others => '0');
    signal s_axi_awvalid : std_logic := '0';
    signal s_axi_awready : std_logic;

    -- AXI-Lite Write Data channel
    signal s_axi_wdata  : std_logic_vector(31 downto 0) := (others => '0');
    signal s_axi_wvalid : std_logic := '0';
    signal s_axi_wready : std_logic;
    signal s_axi_wstrb  : std_logic_vector(3 downto 0) := "1111";

    -- AXI-Lite Write Response channel
    signal s_axi_bresp  : std_logic_vector(1 downto 0);
    signal s_axi_bvalid : std_logic;
    signal s_axi_bready : std_logic := '0';

    -- AXI-Lite Read Address channel
    signal s_axi_araddr  : std_logic_vector(31 downto 0) := (others => '0');
    signal s_axi_arvalid : std_logic := '0';
    signal s_axi_arready : std_logic;

    -- AXI-Lite Read Data channel
    signal s_axi_rdata  : std_logic_vector(31 downto 0);
    signal s_axi_rresp  : std_logic_vector(1 downto 0);
    signal s_axi_rvalid : std_logic;
    signal s_axi_rready : std_logic := '0';

    -- Internal register interface
    signal reg_write_en : std_logic;
    signal reg_read_en  : std_logic;
    signal reg_waddr    : std_logic_vector(31 downto 0);
    signal reg_raddr    : std_logic_vector(31 downto 0);
    signal reg_wdata    : std_logic_vector(31 downto 0);
    signal reg_rdata    : std_logic_vector(31 downto 0) := (others => '0');

    -- Simple register file (6 x 32-bit registers, addresses 0x00 to 0x14) for the memory-mapped interface
    type t_regfile is array(0 to 5) of std_logic_vector(31 downto 0);
    signal regfile : t_regfile := (others => (others => '0'));

    component axi_lite_slave_if
        port (
            clk           : in  std_logic;
            rst_n         : in  std_logic;
            s_axi_awaddr  : in  std_logic_vector(31 downto 0);
            s_axi_awvalid : in  std_logic;
            s_axi_awready : out std_logic;
            s_axi_wdata   : in  std_logic_vector(31 downto 0);
            s_axi_wvalid  : in  std_logic;
            s_axi_wready  : out std_logic;
            s_axi_wstrb   : in  std_logic_vector(3 downto 0);
            s_axi_bresp   : out std_logic_vector(1 downto 0);
            s_axi_bvalid  : out std_logic;
            s_axi_bready  : in  std_logic;
            s_axi_araddr  : in  std_logic_vector(31 downto 0);
            s_axi_arvalid : in  std_logic;
            s_axi_arready : out std_logic;
            s_axi_rdata   : out std_logic_vector(31 downto 0);
            s_axi_rresp   : out std_logic_vector(1 downto 0);
            s_axi_rvalid  : out std_logic;
            s_axi_rready  : in  std_logic;
            reg_write_en  : out std_logic;
            reg_read_en   : out std_logic;
            reg_waddr     : out std_logic_vector(31 downto 0);
            reg_raddr     : out std_logic_vector(31 downto 0);
            reg_wdata     : out std_logic_vector(31 downto 0);
            reg_rdata     : in  std_logic_vector(31 downto 0)
        );
    end component;

begin

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
    dut : axi_lite_slave_if
        port map (
            clk           => clk,
            rst_n         => rst_n,
            s_axi_awaddr  => s_axi_awaddr,
            s_axi_awvalid => s_axi_awvalid,
            s_axi_awready => s_axi_awready,
            s_axi_wdata   => s_axi_wdata,
            s_axi_wvalid  => s_axi_wvalid,
            s_axi_wready  => s_axi_wready,
            s_axi_wstrb   => s_axi_wstrb,
            s_axi_bresp   => s_axi_bresp,
            s_axi_bvalid  => s_axi_bvalid,
            s_axi_bready  => s_axi_bready,
            s_axi_araddr  => s_axi_araddr,
            s_axi_arvalid => s_axi_arvalid,
            s_axi_arready => s_axi_arready,
            s_axi_rdata   => s_axi_rdata,
            s_axi_rresp   => s_axi_rresp,
            s_axi_rvalid  => s_axi_rvalid,
            s_axi_rready  => s_axi_rready,
            reg_write_en  => reg_write_en,
            reg_read_en   => reg_read_en,
            reg_waddr     => reg_waddr,
            reg_raddr     => reg_raddr,
            reg_wdata     => reg_wdata,
            reg_rdata     => reg_rdata
        );

    -- Simple register file model
    -- Writes and reads are performed based on the internal control signals
    regfile_proc : process(clk)
        variable idx : integer;
    begin
        if rising_edge(clk) then
            if reg_write_en = '1' then
                idx := to_integer(unsigned(reg_waddr(5 downto 2)));
                regfile(idx) <= reg_wdata;
            end if;
            if reg_read_en = '1' then
                idx := to_integer(unsigned(reg_raddr(5 downto 2)));
                reg_rdata <= regfile(idx);
            end if;
        end if;
    end process;

     -- Stimulus process
    stim_proc : process

        -- Issue a single write transaction: present AW and W simultaneously
        procedure axi_write (
            addr : in std_logic_vector(31 downto 0);
            data : in std_logic_vector(31 downto 0);
            strb : in std_logic_vector(3 downto 0) := "1111"
        ) is
        begin
            -- Present address and data together
            s_axi_awaddr  <= addr;
            s_axi_awvalid <= '1';
            s_axi_wdata   <= data;
            s_axi_wstrb   <= strb;
            s_axi_wvalid  <= '1';

            
            -- Wait for AW handshake (AWREADY = '1' while AWVALID is held)
            loop
                wait until rising_edge(clk);
                exit when s_axi_awready = '1' and s_axi_wready = '1';
            end loop;
            s_axi_awvalid <= '0';
            s_axi_wvalid  <= '0';

            -- Wait for write response
            loop
                wait until rising_edge(clk);
                exit when s_axi_bvalid = '1';
            end loop;

            s_axi_bready <= '1';
            wait until rising_edge(clk);
            s_axi_bready <= '0';
        end procedure;

        -- Issue a single read transaction
        procedure axi_read (
            addr : in std_logic_vector(31 downto 0)
        ) is
        begin
            -- Present address on the next rising edge
            wait until rising_edge(clk);
            s_axi_araddr  <= addr;
            s_axi_arvalid <= '1';

            -- Wait for AR handshake
            loop
                wait until rising_edge(clk);
                exit when s_axi_arready = '1';
            end loop;
            s_axi_arvalid <= '0';

            -- Wait for read data
            loop
                wait until rising_edge(clk);
                exit when s_axi_rvalid = '1';
            end loop;
            s_axi_rready <= '1';
            wait until rising_edge(clk);
            s_axi_rready <= '0';
        end procedure;

    begin
    
        -- Reset
        rst_n <= '0';
        wait for CLK_PERIOD * 3;
        rst_n <= '1';
        wait for CLK_PERIOD * 2;

        -- Check initial ready signals after reset
        assert s_axi_awready = '0'
            report "FAIL: AWREADY not asserted after reset" severity error;
        assert s_axi_wready = '0'
            report "FAIL: WREADY not asserted after reset" severity error;
        assert s_axi_arready = '0'
            report "FAIL: ARREADY not asserted after reset" severity error;
        assert s_axi_bvalid = '0'
            report "FAIL: BVALID should be deasserted after reset" severity error;
        assert s_axi_rvalid = '0'
            report "FAIL: RVALID should be deasserted after reset" severity error;

        -- ---------------------------------------------------------------
         -- Test 1: Write to register 0 (address 0x00) and verify response
        axi_write(x"00000000", x"DEADBEEF");

        assert s_axi_bresp = "00"
            report "FAIL T1: Expected OKAY response for write to reg 0" severity error;
        assert regfile(0) = x"DEADBEEF"
            report "FAIL T1: Register 0 does not contain expected value 0xDEADBEEF" severity error;

        -- ---------------------------------------------------------------
        -- Test 2: Write to register 1 (address 0x04)
        axi_write(x"00000004", x"CAFEBABE");

        assert s_axi_bresp = "00"
            report "FAIL T2: Expected OKAY response for write to reg 1" severity error;
        assert regfile(1) = x"CAFEBABE"
            report "FAIL T2: Register 1 does not contain expected value 0xCAFEBABE" severity error;

        -- ---------------------------------------------------------------
        -- Test 3: Read back register 0 and verify data
        axi_read(x"00000000");

        assert s_axi_rresp = "00"
            report "FAIL T3: Expected OKAY response for read from reg 0" severity error;
        assert s_axi_rdata = x"DEADBEEF"
            report "FAIL T3: Read data mismatch on reg 0, got 0x" &
                   to_hstring(s_axi_rdata) & " expected 0xDEADBEEF" severity error;

        -- ---------------------------------------------------------------
        -- Test 4: Read back register 1 and verify data
        axi_read(x"00000004");

        assert s_axi_rresp = "00"
            report "FAIL T4: Expected OKAY response for read from reg 1" severity error;
        assert s_axi_rdata = x"CAFEBABE"
            report "FAIL T4: Read data mismatch on reg 1, got 0x" &
                   to_hstring(s_axi_rdata) & " expected 0xCAFEBABE" severity error;

        -- ---------------------------------------------------------------
        -- Test 5: Write with partial byte strobes (upper two bytes only)
        -- Write 0x12345678 with strobe 0b1100 -> only bytes [3:2] updated
        -- reg 2 starts at 0x00, so result should be 0x12340000
        axi_write(x"00000008", x"00000000");  -- clear reg 2 first
        axi_write(x"00000008", x"12345678", "1100");

        assert regfile(2) = x"12340000"
            report "FAIL T5: Byte strobe write incorrect, got 0x" &
                   to_hstring(regfile(2)) & " expected 0x12340000" severity error;

        -- ---------------------------------------------------------------
        -- Test 6: Write to misaligned address -> expect SLVERR
        axi_write(x"00000001", x"AAAAAAAA");

        assert s_axi_bresp = "10"
            report "FAIL T6: Expected SLVERR for misaligned write address" severity error;

        -- ---------------------------------------------------------------
        -- Test 7: Write to out-of-range address -> expect SLVERR
        axi_write(x"00000040", x"BBBBBBBB");

        assert s_axi_bresp = "10"
            report "FAIL T7: Expected SLVERR for out-of-range write address" severity error;

        -- ---------------------------------------------------------------
        -- Test 8: Read from misaligned address -> expect SLVERR
        axi_read(x"00000003");

        assert s_axi_rresp = "10"
            report "FAIL T8: Expected SLVERR for misaligned read address" severity error;

        -- ---------------------------------------------------------------
        -- Test 9: Read from out-of-range address -> expect SLVERR
        axi_read(x"00000040");

        assert s_axi_rresp = "10"
            report "FAIL T9: Expected SLVERR for out-of-range read address" severity error;

        -- ---------------------------------------------------------------
        -- Test 10: Back-to-back writes to consecutive registers
        axi_write(x"0000000C", x"11111111");
        axi_write(x"00000010", x"22222222");
        axi_write(x"00000014", x"33333333");

        assert regfile(3) = x"11111111"
            report "FAIL T10: Register 3 mismatch" severity error;
        assert regfile(4) = x"22222222"
            report "FAIL T10: Register 4 mismatch" severity error;
        assert regfile(5) = x"33333333"
            report "FAIL T10: Register 5 mismatch" severity error;

        -- ---------------------------------------------------------------
        -- Test 11: Write then immediate read (reg 3)
        axi_write(x"0000000C", x"ABCD1234");
        axi_read(x"0000000C");

        assert s_axi_rdata = x"ABCD1234"
            report "FAIL T11: Write-then-read mismatch on reg 3, got 0x" &
                   to_hstring(s_axi_rdata) severity error;

        -- ---------------------------------------------------------------
        -- End of simulation
        wait for CLK_PERIOD * 5;
        assert false
            report "End of simulation - all tests passed" severity note;
        wait;

    end process;

end architecture tb;
