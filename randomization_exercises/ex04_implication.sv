// ## Exercise 4 — Implication Constraints

// Create a class representing a memory access with a write enable bit,
// an 8-bit address, and an 8-bit data field.

// Add constraints so that:
// - When it is a write operation, the address must always be even
// - When it is a read operation, the data field must be zero

// Randomize 10 times and verify both rules are respected.

// **Goals:**
// - Express "if condition, then rule" using the implication operator
// - Understand that the rule is only enforced when the condition is true

class exercise04;
    rand bit access_mode; // 1 - write, 0 - read
    rand bit [7:0] address;
    rand bit [7:0] data;

    constraint implications_c {
        access_mode dist {0 := 1, 1 := 1}; // 50% each one. Not really needed but 
                                           // some solvers tend to favor solutions 
                                           // with larger solution space, which biases
                                           // towards 1

        (access_mode) -> address[0] == 1'b0;
        (!access_mode) -> data == 8'h00;
    }
endclass

module tb;
    initial begin
        exercise04 ex04;
        ex04 = new;
        repeat (20) begin
            if (!ex04.randomize()) $fatal("Randomization failed!");
            else  $display("access_mode: %0d, address: %0d, data: %0d", ex04.access_mode, ex04.address, ex04.data);
        end
    end
endmodule