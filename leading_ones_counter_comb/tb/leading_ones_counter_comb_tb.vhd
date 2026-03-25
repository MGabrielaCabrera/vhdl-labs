library ieee;
use ieee.std_logic_1164.all;
use std.textio.all;
use ieee.std_logic_textio.all;
use ieee.math_real.all;

entity leading_ones_counter_comb_tb is
end entity leading_ones_counter_comb_tb;

architecture tb of leading_ones_counter_comb_tb is
    -- Constants
    constant BITS_IN : natural := 8;
    constant BITS_OUT : natural := integer(ceil(log2(real(BITS_IN+1))));
    constant STIMULUS_FILE_NAME : string := "leading_ones_counter_stimulus.txt";
    
    -- Component declaration
    component leading_ones_counter_comb is
        generic (
            BITS_IN: natural:=BITS_IN
        );
        port (
            input_vector  : in  std_logic_vector(BITS_IN - 1 downto 0);
            leading_ones_count : out std_logic_vector(BITS_OUT - 1 downto 0)
        );
    end component leading_ones_counter_comb;
    
    -- Signals for testbench
    signal input_sig  : std_logic_vector(BITS_IN - 1 downto 0);
    signal output_sig : std_logic_vector(BITS_OUT - 1 downto 0);

begin
    -- Instantiate DUT
    dut : leading_ones_counter_comb
        generic map (
            BITS_IN => BITS_IN
        )
        port map (
            input_vector => input_sig,
            leading_ones_count => output_sig
        );

    -- Stimulus process
    stimulus : process
        file stimulus_file : text open read_mode is STIMULUS_FILE_NAME;
        variable line_buf : line;
        variable input_vector : std_logic_vector(BITS_IN - 1 downto 0);
        variable expected_output : std_logic_vector(BITS_OUT - 1 downto 0);

        function to_string(slv : std_logic_vector) return string is
            variable result : string(1 to slv'length);
        begin
            for i in slv'range loop
                result(slv'length - i) := std_logic'image(slv(i))(2);
            end loop;
            return result;
        end;
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

-- Configuration for RTL architecture
configuration config_rtl of leading_ones_counter_comb_tb is
    for tb
        for dut : leading_ones_counter_comb
            use entity work.leading_ones_counter_comb(rtl);
        end for;
    end for;
end configuration config_rtl;

-- Configuration for behavioral architecture
configuration config_behavioral of leading_ones_counter_comb_tb is
    for tb
        for dut : leading_ones_counter_comb
            use entity work.leading_ones_counter_comb(behavioral);
        end for;
    end for;
end configuration config_behavioral;