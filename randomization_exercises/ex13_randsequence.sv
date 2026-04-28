// ## Exercise 13 — randsequence

// Model a simplified transaction stream where each sequence begins
// with either a write or a read. A write is usually followed by a
// success response but occasionally by an error. A read is always
// followed by a data response.

// Generate 20 sequences and print each step in order.

// **Goals:**
// - Generate ordered, grammar-based stimulus with randsequence
// - Understand when it is the right tool over randcase or constraints
module tb;
    initial begin
        repeat (20) begin
            randsequence (transaction)
            transaction: write_op := 1 | read_op := 1;
            write_op: success_response := 9 | error_response := 1;
            read_op: data_response := 1;
            success_response: {$display("Write operation successful");};
            error_response: {$display("Write operation failed");};
            data_response: {$display("Read operation successful");};
            endsequence
        end
    end
endmodule