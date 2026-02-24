library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

package fir_filter_pkg is

    -- Constants
    constant DATA_WIDTH : integer := 4;
    constant NUM_COEF : integer := 11;
    constant EXTRA_BITS : integer := integer(ceil(log2(real(NUM_COEF))));

    -- Types
    type signed_array is array (0 to NUM_COEF-1) of signed(DATA_WIDTH-1 downto 0);
    type prod_array is array (0 to NUM_COEF-1) of signed(2*DATA_WIDTH-1 downto 0);
    type add_array is array (0 to NUM_COEF-1) of signed(2*DATA_WIDTH+EXTRA_BITS-1 downto 0);
    type coef_array is array (0 to NUM_COEF-1) of integer range -2**(DATA_WIDTH-1) to 2**(DATA_WIDTH-1)-1;
    
    -- Fixed coefficients
    constant COEFS : coef_array := (-8,-5,-5,-1,1,2,2,3,5,7,7);

end package fir_filter_pkg;