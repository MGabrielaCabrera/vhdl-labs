// ## Exercise 3 — Weighted Distributions with dist

// Create a class with a 2-bit packet type and an 8-bit payload.

// Add constraints so that:
// - The packet type follows a weighted distribution where each
//   individual value has its own assigned weight
// - The payload favors the lower half of its range over the upper half,
//   but the weight is split evenly across all values within each half

// Randomize 10000 times, count occurrences of each packet type, and
// verify the distribution roughly matches your weights.

// **Goals:**
// - Assign weight per individual value vs weight shared across a range
// - Observe probabilistic distribution over many iterations

class exercise03;
    rand bit [1:0] pkg_type;
    rand bit [7:0] payload;

    constraint dist_c {
        pkg_type dist {0:= 30, [1:2]:=70}; //0 (30/170), 1 (70/170), 2 (70/170)
        payload dist {[0:126]:/80,[127:254]:/20}; //0-126 (80/127), 127-254 (20/127)
    }
endclass

module tb;
    initial begin
        int pkg_type_count[3];
        int payload_count[255];

        exercise03 ex03;
        ex03 = new;
        repeat (10000) begin
            if (!ex03.randomize()) $fatal("Randomization failed!");
            else begin
                pkg_type_count[ex03.pkg_type]+=1;
                payload_count[ex03.payload]+=1;
            end
        end
        foreach (pkg_type_count[i]) begin
            $display("Packet type %0d: %0d%%", i, pkg_type_count[i]/10000.0*100.0);
        end
        foreach (payload_count[i]) begin
            $display("Payload %0d: %0d%%", i, payload_count[i]/10000.0*100.0);
        end
    end
endmodule