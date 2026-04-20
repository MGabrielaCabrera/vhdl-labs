
// ## Exercise 1 — rand vs randc
// Create a class with two 3-bit variables: one that can repeat values
// across randomization calls, and one that cannot repeat a value until
// all possible values in its range have been generated.
//
// Randomize the class 16 times and print both values on each iteration.
// Observe the difference in behavior between the two variables.
//
// **Goals:**
// - Understand the two types of random variables in SystemVerilog
// - Observe uniform independent draws vs cyclic exhaustion

class exercise01;
   rand bit [2:0] var_rand;
   randc bit [2:0] var_randc;
endclass

module tb;
    initial begin
        exercise01 ex01;
        ex01 = new;
        repeat (16) begin
            if (!ex01.randomize()) $fatal("Randomization failed!");
            else  $display("var_rand: %0d, var_randc: %0d", ex01.var_rand, ex01.var_randc);
        end
    end
endmodule