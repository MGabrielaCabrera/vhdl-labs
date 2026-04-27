// ## Exercise 11 — Array Constraints

// Create a class with a dynamic array of unsigned integers and a
// separate variable that controls how many elements it will have.

// Add constraints so that:
// - The number of elements is in a specific range
// - The array size matches that variable
// - Every element falls within a given range
// - The total sum of all elements stays below a fixed limit
// - Elements are in strictly ascending order

// Randomize 5 times and print the array and its sum each time.

// > When constraining `sum()`, cast each element to a wider type
// > to avoid overflow. Example: `data.sum() with (int'(item)) < 500`

// **Goals:**
// - Constrain size, individual elements, and aggregate properties
// - Apply ordering constraints across array elements with foreach
// - Handle sum overflow correctly

class exercise11;
    rand int unsigned data[];
    rand int unsigned array_size;

    constraint array_constraints_c {
        // The number of elements is in a specific range
        array_size inside {[2:8]};
        // The array size matches that variable
        data.size() == array_size;
        // Every element falls within a given range
        foreach (data[i]) data[i] inside {[0:83]};
        // The total sum of all elements stays below a fixed limit
        data.sum() < 500;
        // Elements are in strictly ascending order
        foreach (data[i]) if (i > 0) data[i] > data[i-1];
    }

    function void print_array();
        $display("array_values:");
        foreach (data[i]) $display("%0d", data[i]);
        $display("sum: %d", int'(data.sum()));
    endfunction
endclass

module tb;
    initial begin
        exercise11 ex11;
        ex11 = new;
        repeat (5) begin
            if (!ex11.randomize()) $fatal("Randomization failed!");
            else ex11.print_array();
        end
    end
endmodule