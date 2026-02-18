--------------------------------------------------------------------------------
-- Engineer:    Gabriela Cabrera
-- 
-- Design:      Leading Ones Counter
-- Module:      leading_ones_counter_comb
-- Description: Counts the number of leading ones in a binary input vector 
--              only using combinational logic.
-- 
-- Date:        29/01/2026
-- Version:     1.0
--------------------------------------------------------------------------------
-- To analyze the RTL architecture, use:
-- ghdl -a leading_ones_counter_comb.vhd
-- To elaborate the design, use:
-- ghdl -e leading_ones_counter_comb.vhd

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity leading_ones_counter_comb is
    generic (
        BITS_IN: natural:=8
    );
    port (
        input_vector  : in  std_logic_vector(BITS_IN - 1 downto 0);
        leading_ones_count  : out std_logic_vector(integer(ceil(log2(real(BITS_IN+1)))) - 1 downto 0)
    );
end entity leading_ones_counter_comb;

architecture rtl of leading_ones_counter_comb is
    constant BITS_OUT : natural := integer(ceil(log2(real(BITS_IN+1))));

    type unsigned_array is array (natural range <>) of 
        unsigned(BITS_OUT - 1 downto 0);
    signal and_array: unsigned(BITS_IN - 1 downto 0);
    signal final_count: unsigned_array(BITS_IN - 1 downto 0);
begin
    -- Generate the AND array to identify leading ones: each bit indicates if all 
    --  previous bits are '1'
    and_array(BITS_IN-1) <= input_vector(BITS_IN-1);
    count_generate: for i in BITS_IN-2 downto 0 generate
    begin
        and_array(i) <= and_array(i+1) and input_vector(i);
    end generate count_generate;

    -- Generate the final count based on the AND array    
    final_count(BITS_IN-1) <= to_unsigned(1, BITS_OUT) when and_array(BITS_IN-1) = '1'
                          else (others => '0');    
    final_count_generate: for i in BITS_IN-2 downto 0 generate
        final_count(i) <= unsigned(final_count(i+1)) + 1 when and_array(i) = '1' else final_count(i+1);
    end generate final_count_generate;

    -- Assign the output to the final count
    leading_ones_count <= std_logic_vector(final_count(0));

end architecture rtl;

architecture behavioral of leading_ones_counter_comb is
begin
    -- Combinational process for leading ones counter
    counter_process : process (input_vector)
        variable count : integer;
    begin
        count := 0;
        for i in BITS_IN - 1 downto 0 loop
            if input_vector(i) = '1' then
                count := count + 1;
            else
                exit;
            end if;
        end loop;
        leading_ones_count <= std_logic_vector(to_unsigned(count, integer(ceil(log2(real(BITS_IN+1))))));
    end process counter_process;

end architecture behavioral;