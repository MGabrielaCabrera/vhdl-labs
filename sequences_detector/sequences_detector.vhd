--------------------------------------------------------------------------------
-- Engineer:    Gabriela Cabrera
-- 
-- Design:     Sequences Detector
-- Module:      sequences_detector
-- Description: Detects specific sequences (1110, 1011, 001) in a binary input stream using FSM.
-- Date:        29/01/2026
-- Version:     1.0
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity sequences_detector is
    port (
        x : in std_logic; -- Input bit stream
        clk : in std_logic; -- Clock signal
        rst : in std_logic; -- Active high reset
        seq_detected : out std_logic; -- Output signal that goes high when a sequence is detected
        seq_counter : out std_logic_vector(31 downto 0) -- Counter for the number of sequences detected
    );
end entity sequences_detector;

architecture fsm of sequences_detector is
    
    -- Define the states for the FSM to detect the sequences 1110, 1011, and 001
    type state_type is (RESET, S1, S11, S111, S10, S101, S0, S00, FOUND);
    signal current_state, next_state : state_type;
    signal counter : unsigned(31 downto 0) := (others => '0');
    
    -- Attribute for FSM state encoding
    attribute FSM_ENCODING : string;
    attribute FSM_ENCODING of current_state : signal is "one_hot";

begin
    -- State transition process
    process (current_state, x)
    begin
        if rst = '1' then
            next_state <= RESET; -- Go to reset state on reset
        else
            case current_state is
                when RESET =>
                    if x = '1' then
                        next_state <= S1;
                    else
                        next_state <= S0;
                    end if;
                when S1 =>
                    if x = '1' then
                        next_state <= S11;
                    else
                        next_state <= S10;
                    end if;
                when S11 =>
                    if x = '1' then
                        next_state <= S111;
                    else
                        next_state <= S0;
                    end if;
                when S111 =>
                    if x = '0' then
                        next_state <= FOUND; -- Sequence 1110 detected
                    else
                        next_state <= S111;
                    end if;
                when S10 =>
                    if x = '1' then
                        next_state <= S101;
                    else
                        next_state <= S00;
                    end if;
                when S101 =>
                    if x = '1' then
                        next_state <= FOUND; -- Sequence 1011 detected
                    else
                        next_state <= S0;
                    end if;
                when S0 =>
                    if x = '0' then
                        next_state <= S00;
                    else
                        next_state <= S1;
                    end if;
                when S00 =>
                    if x = '1' then
                        next_state <= FOUND; -- Sequence 001 detected
                    else
                        next_state <= S00;
                    end if;
                when FOUND =>
                    if x = '1' then
                        next_state <= S1;
                    else
                        next_state <= S0;
                    end if;
                when others =>
                    next_state <= RESET; -- Default case to handle undefined states

            end case;
        end if;
    end process;

    -- Output logic and counter update process
    process (clk, rst)
    begin
        if rst = '1' then
            current_state <= RESET;
            counter <= (others => '0');
            seq_detected <= '0';
        elsif rising_edge(clk) then
            current_state <= next_state;
            if next_state = FOUND then -- To change the fsm to moore, change this condition to current_state = FOUND 
                                       -- (latency of one clock cycle for seq_detected to go high)
                counter <= counter + 1; -- Increment counter on sequence detection
                seq_detected <= '1'; -- Set output high when a sequence is detected
            else
                seq_detected <= '0'; -- Set output low otherwise
            end if;
        end if;
    end process;

    seq_counter <= std_logic_vector(counter); -- Assign the counter value to the outputS

end architecture;