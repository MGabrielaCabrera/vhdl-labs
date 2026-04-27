// ## Exercise 12 — randcase

// In a testbench module, without using a class, simulate a bus arbiter
// that selects one of three masters. Assign different weights to each
// master so that one is selected most often and one the least.

// Run 1000 selections, count the results, and verify they roughly
// match your intended weights.

// **Goals:**
// - Make weighted random choices procedurally without a class
// - Understand randcase as a lightweight alternative for simple
//   weighted selection

module tb;
    initial begin
        int master_counter[3];
        repeat(1000) begin
            randcase
                7: master_counter[0]++;
                2: master_counter[1]++;
                1: master_counter[2]++;
            endcase
        end

        $display("Results:");
        $display("master_counter[0] = %0d", master_counter[0]);
        $display("master_counter[1] = %0d", master_counter[1]);
        $display("master_counter[2] = %0d", master_counter[2]);
    end
endmodule