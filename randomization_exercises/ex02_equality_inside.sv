// ## Exercise 2 — Equality and Set Membership Constraints

// Create a class representing a bus transaction with an 8-bit address,
// an 8-bit data field, and a 2-bit burst length.

// Add constraints so that:
// - The address is restricted to a specific contiguous range
// - The data can only take a small set of specific byte values
// - The burst length is always the same fixed value

// Randomize 10 times and verify all constraints hold.

// **Goals:**
// - Fix a variable to a specific value using a constraint
// - Restrict a variable to a range or an explicit list of values

class exercise02;
   rand bit [7:0] address;
   rand bit [7:0] data;
   rand bit [1:0] len;

   // Nonrandom variables used as limits
   int lo = 16;
   int hi = 64;

   constraint exercise02_c {
    address inside {[lo:hi]};
    data inside {8'h00, [8'h05:8'h0F], 8'hFF};
    len == 2;
   };
endclass

module tb;
    initial begin
        exercise02 ex02;
        ex02 = new;
        repeat (10) begin
            if (!ex02.randomize()) $fatal("Randomization failed!");
            else  $display("address: %0d, data: %0d, len: %0d", ex02.address, ex02.data, ex02.len);
        end
    end
endmodule