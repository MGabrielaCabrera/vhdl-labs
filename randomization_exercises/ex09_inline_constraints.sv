// ## Exercise 9 — Inline Constraints

// Create a class with an 8-bit address and an 8-bit data field.
// Define no constraints inside the class itself.

// In the testbench, run three rounds of 5 randomizations each:
// 1. No extra constraints
// 2. Force the address above a high threshold
// 3. Force data to be odd and address below a low threshold

// Do not modify the class for any round.

// **Goals:**
// - Add one-off constraints directly at the call site
// - Understand why this is useful for directed tests without
//   touching the original class

class exercise09;
   rand bit [7:0] address;
   rand bit [7:0] data;

   // Nonrandom variables used as limits
   int lo = 16;
   int hi = 64;

endclass

module tb;
    initial begin
        exercise09 ex09;
        ex09 = new;

        // No extra constraints
        $display("No extra constraints:");
        repeat (5) begin
            if (!ex09.randomize()) $fatal("Randomization failed!");
            else  $display("address: %0d, data: %0d", ex09.address, ex09.data);
        end

        // Force the address above a high threshold
        $display("Force the address above a high threshold:");
        repeat (5) begin
            if (!ex09.randomize() with {address > 8'h0F;}) $fatal("Randomization failed!");
            else  $display("address: %0d, data: %0d", ex09.address, ex09.data);
        end

        // Force data to be odd and address below a low threshold
        $display("Force data to be odd and address below a low threshold");
        repeat (5) begin
            if (!ex09.randomize() with {address < 8'h0F; data[0] != 1'b0;}) $fatal("Randomization failed!");
            else  $display("address: %0d, data: %0d", ex09.address, ex09.data);
        end

    end
endmodule