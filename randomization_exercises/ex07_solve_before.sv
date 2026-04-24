// ## Exercise 7 — solve...before

// Create a class with a 1-bit flag and a 3-bit value. Add a constraint
// so that when the flag is set, the value must be zero.

// Without any ordering hint, randomize 1000 times and count how often
// the flag is set. Then add a directive that tells the solver to
// determine the flag first, before solving for the value. Randomize
// 1000 times again and compare the flag distribution.

// **Goals:**
// - Guide solver ordering to change the probability of outcomes
// - Understand that this does not change which solutions are legal,
//   only how often each is chosen

class exercise07;
    rand bit flag;
    rand bit [2:0] value;

    constraint simpler_c {
        (flag == 1) -> (value == 4'h0);
    }
    constraint solve_flag_before_value_c {
        solve flag before value;
    }
    constraint solve_value_before_flag_c {
        solve value before flag;
    }  

endclass

module tb;
    initial begin
        int flag_set_count[8];
        int flag_non_set_count[8];

        exercise07 ex07;
        ex07 = new;
        
        //------------------------------------------------------------------
        // Disable solve-before constraints to see the default distribution
        ex07.solve_flag_before_value_c.constraint_mode(0);
        ex07.solve_value_before_flag_c.constraint_mode(0);
        ex07.simpler_c .constraint_mode(1); // Just to be sure, enable the main constraint
        $display("Running randomize without solve-before...");
        repeat (1000) begin
            if (!ex07.randomize()) $fatal("Randomization failed!");
            else begin
                if (ex07.flag == 1'b0) flag_non_set_count[ex07.value]+=1;
                else flag_set_count[ex07.value]+=1;
            end 
        end
        $display("Flag not set distribution:");
        foreach (flag_non_set_count[i]) begin
            $display("Value %0d: %0d%%", i, flag_non_set_count[i]/1000.0*100.0);
        end
        $display("Flag set distribution:");
        foreach (flag_set_count[i]) begin
            $display("Value %0d: %0d%%", i, flag_set_count[i]/1000.0*100.0);
        end

        //------------------------------------------------------------------
        // Reset counts
        foreach (flag_set_count[i]) flag_set_count[i] = 0;
        foreach (flag_non_set_count[i]) flag_non_set_count[i] = 0;
        ex07.solve_flag_before_value_c.constraint_mode(1);
        $display("Running randomize with solve flag before value...");
        repeat (1000) begin
            if (!ex07.randomize()) $fatal("Randomization failed!");
            else begin
                if (ex07.flag == 1'b0) flag_non_set_count[ex07.value]+=1;
                else flag_set_count[ex07.value]+=1;
            end 
        end
        $display("Flag not set distribution:");
        foreach (flag_non_set_count[i]) begin
            $display("Value %0d: %0d%%", i, flag_non_set_count[i]/1000.0*100.0);
        end
        $display("Flag set distribution:");
        foreach (flag_set_count[i]) begin
            $display("Value %0d: %0d%%", i, flag_set_count[i]/1000.0*100.0);
        end

        //------------------------------------------------------------------
        // Reset counts
        foreach (flag_set_count[i]) flag_set_count[i] = 0;
        foreach (flag_non_set_count[i]) flag_non_set_count[i] = 0;
        ex07.solve_flag_before_value_c.constraint_mode(0);
        ex07.solve_value_before_flag_c.constraint_mode(1);
        $display("Running randomize with solve value before flag...");
        repeat (1000) begin
            if (!ex07.randomize()) $fatal("Randomization failed!");
            else begin
                if (ex07.flag == 1'b0) flag_non_set_count[ex07.value]+=1;
                else flag_set_count[ex07.value]+=1;
            end 
        end
        $display("Flag not set distribution:");
        foreach (flag_non_set_count[i]) begin
            $display("Value %0d: %0d%%", i, flag_non_set_count[i]/1000.0*100.0);
        end
        $display("Flag set distribution:");
        foreach (flag_set_count[i]) begin
            $display("Value %0d: %0d%%", i, flag_set_count[i]/1000.0*100.0);
        end

        //------------------------------------------------------------------

    end
endmodule