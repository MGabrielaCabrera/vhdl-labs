library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.fir_filter_pkg.all;

entity fir_filter_tb is
end entity fir_filter_tb;

architecture tb of fir_filter_tb is
	constant CLK_PERIOD : time := 10 ns;
    constant test_coefficients : coef_array := (0,1,2,3,4,5,0,1,2,3,4); -- New coefficients for testing

	signal clk : std_logic := '0';
	signal rst : std_logic := '1';
	signal din : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
	signal dout : std_logic_vector(2*DATA_WIDTH+integer(ceil(log2(real(NUM_COEF))))-1 downto 0);
	signal coef_we : std_logic := '0';
	signal coef_addr : integer range 0 to NUM_COEF-1 := 0;
	signal coef_data : integer range -2**(DATA_WIDTH-1) to 2**(DATA_WIDTH-1)-1 := 0; -- Initialize with fixed coefficients
	signal coef_setting: boolean:= False; -- Flag to indicate when coefficients are being set
	
	component fir_filter
        port (
            clk : in std_logic;
            rst : in std_logic;
			coef_we: in std_logic;
			coef_addr: in integer range 0 to NUM_COEF-1;
			coef_data: in integer range -2**(DATA_WIDTH-1) to 2**(DATA_WIDTH-1)-1;
            din : in std_logic_vector(DATA_WIDTH-1 downto 0);
            dout : out std_logic_vector(2*DATA_WIDTH+integer(ceil(log2(real(NUM_COEF))))-1 downto 0)
        );
    end component;

begin
	-- Clock generation
	clk_process : process
	begin
		while now < 500 ns loop
			clk <= '1'; wait for CLK_PERIOD/2;
			clk <= '0'; wait for CLK_PERIOD/2;
		end loop;
		wait;
	end process;

	-- DUT instantiation
	dut:  fir_filter
		port map (
			clk => clk,
			rst => rst,
			coef_we => coef_we,
			coef_addr => coef_addr,
			coef_data => coef_data,
			din => din,
			dout => dout
		);

	-- Stimulus process
	stim_proc: process
	    variable i : integer range 0 to NUM_COEF := 0; -- Variable to iterate through coefficients
	begin
		-- Reset
		i:= 0;
		rst <= '1';
		wait for 2*CLK_PERIOD;
		rst <= '0';

		-- Write coefficients (overwriting fixed ones)
		while i < NUM_COEF loop
			coef_addr <= i;
			coef_data <= test_coefficients(i);
			coef_we   <= '1';
			wait for CLK_PERIOD;
			coef_we   <= '0';
			wait for CLK_PERIOD;
			i := i + 1;
		end loop;
		coef_setting <= True; -- Set flag to indicate coefficients have been set

		-- Impulse input
		din <= std_logic_vector(to_signed(1, DATA_WIDTH));
		wait for CLK_PERIOD;
		din <= (others => '0');

		-- Wait for all outputs
		wait for (NUM_COEF+2)*CLK_PERIOD;
		wait;
	end process;

	-- Output check process
	check_proc: process(clk, rst)
		variable sample : integer := 0;
	begin
			if rst = '1' then
				sample := 0;
			elsif falling_edge(clk) then -- Check on falling edge to allow output 
				                         -- to stabilize after clock edge
			    if sample < NUM_COEF and coef_setting = True then
                    assert dout = std_logic_vector(to_signed(test_coefficients(sample), dout'length))
                    report "Mismatch: Input=" & integer'image(sample) & 
                            " Expected=" & integer'image(test_coefficients(sample)) & 
                            " Got=" & integer'image(to_integer(signed(dout)))
                    severity error;
				    sample := sample + 1;
			    end if;
			end if;
	end process;

end architecture tb;

-- Configuration for chain arranged adders architecture
configuration config_rtl_chain_arranged_adders of fir_filter_tb is
    for tb
        for dut : fir_filter
            use entity work.fir_filter(rtl_chain_arranged_adders);
        end for;
    end for;
end configuration config_rtl_chain_arranged_adders;

-- Configuration for pipeline arranged adders architecture
configuration config_rtl_pipeline_arranged_adders of fir_filter_tb is
    for tb
        for dut : fir_filter
            use entity work.fir_filter(rtl_pipeline_arranged_adders);
        end for;
    end for;
end configuration config_rtl_pipeline_arranged_adders;