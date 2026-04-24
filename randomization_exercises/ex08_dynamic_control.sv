// ## Exercise 8 — constraint_mode and rand_mode

// Reuse the class from Exercise 2. In your testbench:

// 1. Disable the address range constraint at runtime. Randomize 5 times
//    and verify the address is no longer restricted.
// 2. Re-enable it.
// 3. Prevent the data field from changing on each randomization call.
//    Randomize 5 more times and verify it stays fixed.
// 4. Re-enable normal randomization for data.

// **Goals:**
// - Toggle specific constraint blocks on and off during simulation
// - Freeze a random variable to its current value for specific tests

class exercise08;
   rand bit [7:0] address;
   rand bit [7:0] data;
   rand bit [1:0] len;

   // Nonrandom variables used as limits
   int lo = 16;
   int hi = 64;

   constraint exercise08_addr_c {
    address inside {[lo:hi]};

   };
   constraint exercise08_data_and_len_c {
    data inside {8'h00, [8'h05:8'h0F], 8'hFF};
    len == 2;
   };
endclass

module tb;
    initial begin
        exercise08 ex08;
        ex08 = new;

        // Disabling address constraint
        ex08.exercise08_addr_c.constraint_mode(0);
        $display("Disabling address constraint");
        repeat (5) begin
            if (!ex08.randomize()) $fatal("Randomization failed!");
            else  $display("address: %0d, data: %0d, len: %0d", ex08.address, ex08.data, ex08.len);
        end
   
        // Re-enabling address constraint
        ex08.exercise08_addr_c.constraint_mode(1);

        // Preventing the data field from changing
        ex08.data.rand_mode(0);
        $display("Preventing the data field from changing");
        repeat (5) begin
            if (!ex08.randomize()) $fatal("Randomization failed!");
            else  $display("address: %0d, data: %0d, len: %0d", ex08.address, ex08.data, ex08.len);
        end
        
        // Re-enabling value
        ex08.data.rand_mode(1);

    end
endmodule