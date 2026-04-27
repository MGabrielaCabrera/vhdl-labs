// ## Exercise 10 — pre_randomize and post_randomize

// Create a class with a 4-element fixed array of 8-bit values and
// two non-random fields: one used as an upper bound for the array
// values, and one that stores a derived result.

// Before each randomization, set the upper bound to a chosen value
// and make sure the constraint respects it. After each randomization,
// compute the derived field as the XOR of all array elements.

// Randomize 5 times, print the array and the derived value, and
// manually verify one result by hand.

// **Goals:**
// - Configure non-random state before the solver runs
// - Derive secondary fields from freshly randomized values

class exercise10;
    rand bit [7:0] data[0:3];
    int upper_bound;
    bit [7:0] derived_result;

    constraint pre_pos_randimize_c {
        foreach (data[i]) data[i] < upper_bound;
    }

    function void pre_randomize();
        upper_bound = 200;
    endfunction

    function void post_randomize();
        foreach (data[i]) derived_result ^= data[i];
    endfunction

    function void print_array();
        $display("array_values:");
        foreach (data[i]) $display("%0d", data[i]);
        $display("xor result: %0d", derived_result);
    endfunction
endclass

module tb;
    initial begin
        exercise10 ex10;
        ex10 = new;
        repeat (5) begin
            if (!ex10.randomize()) $fatal("Randomization failed!");
            else ex10.print_array();
        end
    end
endmodule