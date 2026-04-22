// ## Exercise 5 — Conditional Constraints (if-else)

// Create a class with a write enable bit, an 8-bit data field,
// and a 2-bit mode selector.

// Add a single constraint block so that:
// - Write operations produce non-zero data and restrict the mode to
//   a specific subset of values
// - Read operations force data to zero and fix the mode to a
//   specific value

// Randomize 10 times and confirm every case follows the rules.

// **Goals:**
// - Use if-else inside a constraint block for multi-branch logic
// - Understand that constraints are solved simultaneously, not
//   sequentially like procedural code

class exercise05;
    rand bit write_enable; // 1 - write, 0 - read
    rand bit [7:0] data;
    rand bit [1:0] mode_selector;

    constraint if_else_c {
        write_enable dist {0 := 1, 1 := 1}; // 50% each one. Not really needed but 
                                           // some solvers tend to favor solutions 
                                           // with larger solution space, which biases
                                           // towards 1
        if (write_enable == 1'b1) { data != 8'h00; mode_selector inside {2'b01, 2'b11};}
        else { data == 0'h00; mode_selector == 2'b10;}
    }
endclass

module tb;
    initial begin
        exercise05 ex05;
        ex05 = new;
        repeat (10) begin
            if (!ex05.randomize()) $fatal("Randomization failed!");
            else  $display("write_enable: %0d, data: %0d, mode_selector: %0d", ex05.write_enable, ex05.data, ex05.mode_selector);
        end
    end
endmodule