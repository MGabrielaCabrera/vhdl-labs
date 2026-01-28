library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity leading_ones_counter_comb is
    generic (
        BITS_IN: natural:=8;
        BITS_OUT: natural:=integer(ceil(log2(real(BITS_IN+1))))
    );
    port (
        input  : in  std_logic_vector(BITS_IN - 1 downto 0);
        leading_ones_count  : out std_logic_vector(BITS_OUT - 1 downto 0)
    );
end entity leading_ones_counter_comb;

architecture rtl of leading_ones_counter_comb is
begin

end architecture rtl;