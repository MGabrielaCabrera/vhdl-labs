// ## Exercise 6 — Bidirectional Constraints

// Create a class with a 1-bit flag and a 4-bit value. Add a single
// constraint that ties the flag directly to whether the value exceeds
// a threshold.

// Randomize 10 times and verify that the flag is always consistent
// with the value. Then, without changing the class, force the flag
// to be set from the testbench and observe how the value is
// automatically restricted as a consequence.

// **Goals:**
// - Observe that the solver satisfies all constraints simultaneously
// - Understand that fixing one variable can implicitly constrain others

class exercise06;
    rand bit flag;
    rand bit [3:0] value;

    constraint bidirectional_c {
        flag == (value > 4'h5);
    }
endclass

module tb;
    initial begin
        exercise06 ex06;
        ex06 = new;
        $display("Verifying that flag is always consistent with the value...");
        repeat (10) begin
            if (!ex06.randomize()) $fatal("Randomization failed!");
            else  $display("flag: %0d, value: %0d", ex06.flag, ex06.value);
        end
        $display("Forcing flag to be 0");
        repeat (10) begin
            if (!ex06.randomize() with {ex06.flag == 1'b0;}) $fatal("Randomization failed!");
            else  $display("flag: %0d, value: %0d", ex06.flag, ex06.value);
        end
    end
endmodule