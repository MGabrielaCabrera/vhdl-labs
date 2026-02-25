library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.fir_filter_pkg.all;

entity fir_filter is
    port (
        clk : in std_logic;
        rst : in std_logic;
        din : in std_logic_vector(DATA_WIDTH-1 downto 0);
        dout : out std_logic_vector(2*DATA_WIDTH+EXTRA_BITS-1 downto 0)
    );
end entity fir_filter;

-- This architecture implements a FIR filter using a chain of adders.
-- The latency is one because the additions are done sequentially. 
-- The delay is related to the number of additions plus the multiplication
-- so it is higher than the other architectures.
architecture rtl_chain_arranged_adders of fir_filter is

    -- Internal signals
    signal shift_reg : signed_array := (others => (others => '0'));
    signal prod : prod_array := (others => (others => '0'));
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
    
    -- Add the products together: this is where the chain of adders is implemented.
    -- The HW is replicated but not paralilelized, because the result value 
    -- depends on the previos value so the additions are done sequentially.
    add(0) <= resize(prod(0), 2*DATA_WIDTH+EXTRA_BITS);
    adder: for i in 1 to NUM_COEF-1 generate
        add(i) <= add(i-1) + resize(prod(i), 2*DATA_WIDTH+EXTRA_BITS);
    end generate;
    
    dout <= std_logic_vector(add(NUM_COEF-1));


end architecture rtl_chain_arranged_adders;

architecture rtl_pipeline_arranged_adders of fir_filter is
    -- Internal signals
    signal add_pipe : add_array := (others => (others => '0'));
    signal din_d: signed(DATA_WIDTH-1 downto 0) := (others => '0');

begin

    -- Pipeline the adder chain: only register the output of each sum
    process(clk)
    begin

        if rising_edge(clk) then
            if rst = '1' then
                add_pipe <= (others => (others => '0'));
                din_d <= (others => '0');
            else
                din_d <= signed(din);
                add_pipe(0) <= resize(din_d * to_signed(COEFS(NUM_COEF-1), 2*DATA_WIDTH+EXTRA_BITS), 2*DATA_WIDTH+EXTRA_BITS);
                for i in 1 to NUM_COEF-1 loop
                    add_pipe(i) <= add_pipe(i-1) + resize(din_d * to_signed(COEFS(NUM_COEF-1-i), 2*DATA_WIDTH+EXTRA_BITS), 2*DATA_WIDTH+EXTRA_BITS);
                end loop;
            end if;
        end if;
    end process;

    dout <= std_logic_vector(add_pipe(NUM_COEF-1));

end architecture rtl_pipeline_arranged_adders;