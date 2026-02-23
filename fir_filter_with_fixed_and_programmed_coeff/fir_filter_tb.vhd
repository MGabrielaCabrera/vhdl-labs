library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fir_filter_tb is
end entity fir_filter_tb;

architecture testbench of fir_filter_tb is
	constant DATA_WIDTH : integer := 16;
	constant NUM_TAPS : integer := 11;
	signal clk : std_logic := '0';
	signal rst : std_logic := '1';
	signal din : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
	signal dout : std_logic_vector(2*(DATA_WIDTH+3)-1 downto 0);

	-- Fixed coefficients for reference
	type coef_array is array (0 to NUM_TAPS-1) of integer;
	constant COEFS : coef_array := (-8,-5,-5,-1,1,2,2,3,5,7,7);

begin
	-- Clock generation
	clk_process : process
	begin
		while now < 500 ns loop
			clk <= '0'; wait for 5 ns;
			clk <= '1'; wait for 5 ns;
		end loop;
		wait;
	end process;

	-- DUT instantiation
	dut: entity work.fir_filter
		generic map (
			DATA_WIDTH => DATA_WIDTH,
			NUM_TAPS => NUM_TAPS
		)
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
		wait for (NUM_TAPS+2)*10 ns;
		wait;
	end process;

	-- Output check process
	check_proc: process(clk)
		variable sample : integer := 0;
	begin
		if rising_edge(clk) then
			if rst = '1' then
				sample := 0;
			elsif sample < NUM_TAPS then
                assert dout = std_logic_vector(to_signed(COEFS(sample), dout'length))
                report "Mismatch: Input=" & integer'image(sample) & 
                        " Expected=" & integer'image(COEFS(sample)) & 
                        " Got=" & integer'image(to_integer(signed(dout)))
                severity error;
				sample := sample + 1;
			end if;
		end if;
	end process;

end architecture testbench;

-- Configuration for chain arranged adders architecture
configuration config_rtl_chain_arranged_adders of fir_filter_tb is
    for tb
        for dut : fir_filter
            use entity work.fir_filter(rtl_chain_arranged_adders);
        end for;
    end for;
end configuration config_rtl_chain_arranged_adders;

-- Configuration for three arranged adders architecture
configuration config_rtl_three_arranged_adders of fir_filter_tb is
    for tb
        for dut : fir_filter
            use entity work.fir_filter(rtl_three_arranged_adders);
        end for;
    end for;
end configuration config_rtl_three_arranged_adders;

-- Configuration for pipeline arranged adders architecture
configuration config_rtl_pipeline_arranged_adders of fir_filter_tb is
    for tb
        for dut : fir_filter
            use entity work.fir_filter(rtl_pipeline_arranged_adders);
        end for;
    end for;
end configuration config_rtl_pipeline_arranged_adders;