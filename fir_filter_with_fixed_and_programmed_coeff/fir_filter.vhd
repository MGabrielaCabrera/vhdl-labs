library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity fir_filter is
    generic (
        DATA_WIDTH : integer := 4;
        NUM_COEF : integer := 11
    );
    port (
        clk : in std_logic;
        rst : in std_logic;
        din : in std_logic_vector(DATA_WIDTH-1 downto 0);
        dout : out std_logic_vector(2*DATA_WIDTH+integer(ceil(log2(real(NUM_COEF))))-1 downto 0)
    );
end entity fir_filter;

architecture rtl_chain_arranged_adders of fir_filter is

    constant EXTRA_BITS : integer := integer(ceil(log2(real(NUM_COEF))));

    -- Filter coefficients (fixed for this example)
    type coef_array is array (0 to NUM_COEF-1) of integer range -2**(DATA_WIDTH-1) to 2**(DATA_WIDTH-1)-1;
    constant COEFS : coef_array := (-8,-5,-5,-1,1,2,2,3,5,7,7);

    -- Internal signals
    type signed_array is array (0 to NUM_COEF-1) of signed(DATA_WIDTH-1 downto 0);
    signal shift_reg : signed_array := (others => (others => '0'));
    type prod_array is array (0 to NUM_COEF-1) of signed(2*DATA_WIDTH-1 downto 0);
    signal prod : prod_array := (others => (others => '0'));
    type add_array is array (0 to NUM_COEF-1) of signed(2*DATA_WIDTH+EXTRA_BITS-1 downto 0);
    signal add : add_array := (others => (others => '0'));

begin
    
    -- Shift register process
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                shift_reg <= (others => (others => '0'));
            else
                shift_reg(0) <= signed(din);
                for i in 1 to NUM_COEF-1 loop
                    shift_reg(i) <= shift_reg(i-1);
                end loop;
            end if;
        end if;
    end process;

    -- Multiply coefficients with shift register values
    gen_mult: for i in 0 to NUM_COEF-1 generate
        prod(i) <= shift_reg(i) * to_signed(COEFS(i), DATA_WIDTH);
    end generate;
    
    -- Add the products together
    add(0) <= resize(prod(0), 2*DATA_WIDTH+EXTRA_BITS);
    adder: for i in 1 to NUM_COEF-1 generate
        add(i) <= add(i-1) + resize(prod(i), 2*DATA_WIDTH+EXTRA_BITS);
    end generate;
    
    dout <= std_logic_vector(add(NUM_COEF-1));


end architecture rtl_chain_arranged_adders;

architecture rtl_three_arranged_adders of fir_filter is
begin

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                dout <= (others => '0');
            else
                -- FIR filter logic here
            end if;
        end if;
    end process;

end architecture rtl_three_arranged_adders;

architecture rtl_pipeline_arranged_adders of fir_filter is
begin

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                dout <= (others => '0');
            else
                -- FIR filter logic here
            end if;
        end if;
    end process;

end architecture rtl_pipeline_arranged_adders;