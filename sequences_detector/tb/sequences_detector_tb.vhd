library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sequences_detector_tb is
end entity sequences_detector_tb;

architecture tb of sequences_detector_tb is
    constant CLK_PERIOD : time := 10 ns;

    signal clk : std_logic := '0';
    signal rst : std_logic := '1';
    signal x : std_logic := '0';
    signal seq_detected : std_logic;
    signal seq_counter : std_logic_vector(31 downto 0);

    component sequences_detector
        port (
            x : in std_logic;
            clk : in std_logic;
            rst : in std_logic;
            seq_detected : out std_logic;
            seq_counter : out std_logic_vector(31 downto 0)
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
    dut: sequences_detector
        port map (
            x => x,
            clk => clk,
            rst => rst,
            seq_detected => seq_detected,
            seq_counter => seq_counter
        );

    -- Stimulus process
    stim_proc: process
    begin
        -- Apply reset
        rst <= '1'; wait for CLK_PERIOD*2;
        rst <= '0'; wait for CLK_PERIOD*2;

        -- Test sequence 1110
        x <= '1'; wait for CLK_PERIOD;
        x <= '1'; wait for CLK_PERIOD;
        x <= '1'; wait for CLK_PERIOD;
        x <= '0'; wait for CLK_PERIOD+CLK_PERIOD/2; -- Wait for the next clock edge to check the output

        assert seq_detected = '1' report "Failed to detect sequence 1110" severity error;

        -- Test sequence 1011
        x <= '1'; wait for CLK_PERIOD;
        x <= '0'; wait for CLK_PERIOD;
        x <= '1'; wait for CLK_PERIOD;
        x <= '1'; wait for CLK_PERIOD+CLK_PERIOD/2; -- Wait for the next clock edge to check the output

        assert seq_detected = '1' report "Failed to detect sequence 1011" severity error;

        -- Test sequence 001
        x <= '0'; wait for CLK_PERIOD;
        x <= '0'; wait for CLK_PERIOD;
        x <= '1'; wait for CLK_PERIOD+CLK_PERIOD/2; -- Wait for the next clock edge to check the output

        assert seq_detected = '1' report "Failed to detect sequence 001" severity error;

         -- Test no sequence
        x <= '0'; wait for CLK_PERIOD;
        x <= '0'; wait for CLK_PERIOD;
        x <= '0'; wait for CLK_PERIOD+CLK_PERIOD/2; -- Wait for the next clock edge to check the output

        assert seq_detected = '0' report "Failed to detect no sequence" severity error;

        assert seq_counter = X"00000003" report "Sequence counter did not count correctly, its value is " & integer'image(to_integer(unsigned(seq_counter))) severity error;

        rst <= '1'; wait for CLK_PERIOD*2;
        rst <= '0'; wait for CLK_PERIOD*2;
        assert seq_counter = X"00000000" report "Counter did not reset correctly, its value is " & integer'image(to_integer(unsigned(seq_counter))) severity error;

        -- Wait and finish simulation
        wait for 100 ns;
        assert false report "End of simulation" severity note;
        wait;
    end process;

end architecture tb;