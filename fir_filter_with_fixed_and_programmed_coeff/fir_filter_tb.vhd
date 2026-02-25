library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.fir_filter_pkg.all;

entity fir_filter_tb is
end entity fir_filter_tb;

architecture tb of fir_filter_tb is
	signal clk : std_logic := '0';
	signal rst : std_logic := '1';
	signal din : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
	signal dout : std_logic_vector(2*DATA_WIDTH+integer(ceil(log2(real(NUM_COEF))))-1 downto 0);
	
	component fir_filter
        port (
            clk : in std_logic;
            rst : in std_logic;
            din : in std_logic_vector(DATA_WIDTH-1 downto 0);
            dout : out std_logic_vector(2*DATA_WIDTH+integer(ceil(log2(real(NUM_COEF))))-1 downto 0)
        );
    end component;

begin
	-- Clock generation
	clk_process : process
	begin
		while now < 500 ns loop
			clk <= '1'; wait for 5 ns;
			clk <= '0'; wait for 5 ns;
		end loop;
		wait;
	end process;

	-- DUT instantiation
	dut:  fir_filter
		port map (
			clk => clk,
			rst => rst,
			din => din,
			dout => dout
		);

	-- Stimulus process
	stim_proc: process
	begin
		-- Reset
		rst <= '1';
		wait for 20 ns;
		rst <= '0';

		-- Impulse input
		din <= std_logic_vector(to_signed(1, DATA_WIDTH));
		wait for 10 ns;
		din <= (others => '0');

		-- Wait for all outputs
		wait for (NUM_COEF+11)*10 ns;
		wait;
	end process;

	-- Output check process
	check_proc: process(clk, rst)
		variable sample : integer := 0;
	begin
			if rst = '1' then
				sample := 0;
			elsif rising_edge(clk) then -- Check on falling edge to allow output 
				                         -- to stabilize after clock edge
			    if sample >= 1 and sample < NUM_COEF then
                    assert dout = std_logic_vector(to_signed(COEFS(sample), dout'length))
                    report "Mismatch: Input=" & integer'image(sample) & 
                            " Expected=" & integer'image(COEFS(sample)) & 
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