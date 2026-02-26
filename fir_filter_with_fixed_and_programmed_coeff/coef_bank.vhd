library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.fir_filter_pkg.all;

entity coef_bank is
    port(
        clk        : in std_logic;
        rst        : in std_logic;
        coef_we    : in std_logic;
        coef_addr  : in integer range 0 to NUM_COEF-1;
        coef_data  : in integer range -2**(DATA_WIDTH-1) to 2**(DATA_WIDTH-1)-1;
        coefs_out  : out coef_array
    );
end entity;

architecture rtl of coef_bank is
    signal coefs_reg : coef_array;
begin

process(clk)
begin
    if rising_edge(clk) then
        if rst = '1' then
            coefs_reg <= COEFS;
        elsif coef_we = '1' then
            coefs_reg(coef_addr) <= coef_data;
        end if;
    end if;
end process;

coefs_out <= coefs_reg;

end rtl;