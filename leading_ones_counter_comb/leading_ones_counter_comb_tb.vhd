library ieee;
use ieee.std_logic_1164.all;
use std.textio.all;
use ieee.std_logic_textio.all;

entity leading_ones_counter_comb_tb is
end entity leading_ones_counter_comb_tb;

architecture tb of leading_ones_counter_comb_tb is
    -- Constants
    constant BITS_IN : natural := 8;
    constant BITS_OUT : natural := 4;
    
    -- Signals for testbench
    signal input_sig  : std_logic_vector(BITS_IN - 1 downto 0);
    signal output_sig : std_logic_vector(BITS_OUT - 1 downto 0);

begin
    -- Instantiate DUT
    dut : entity work.leading_ones_counter_comb
        generic map (
            BITS_IN => BITS_IN,
            BITS_OUT => BITS_OUT
        )
        port map (
            input_vector => input_sig,
            leading_ones_count => output_sig
        );

    -- Stimulus process
    stimulus : process
        file stimulus_file : text open read_mode is "leading_ones_counter_stimulus.txt";
        variable line_buf : line;
        variable input_vector : std_logic_vector(BITS_IN - 1 downto 0);
        variable expected_output : std_logic_vector(BITS_OUT - 1 downto 0);
    begin
        while not endfile(stimulus_file) loop
            readline(stimulus_file, line_buf);
            read(line_buf, input_vector);
            read(line_buf, expected_output);
            input_sig <= input_vector;
            wait for 80 ns;
            assert output_sig = expected_output
                report "Mismatch: Input=" & to_string(input_vector) & 
                        " Expected=" & to_string(expected_output) & 
                        " Got=" & to_string(output_sig)
                severity error;
        end loop;
        file_close(stimulus_file);
        wait;
    end process stimulus;

end architecture tb;