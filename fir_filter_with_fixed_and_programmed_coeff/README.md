## Lab description
This test consists of designing and evaluating a VHDL implementation of a Finite Impulse Response (FIR) filter that supports both fixed and programmable coefficients, selectable through a boolean generic constant. The design must include twp alternative architectures: (1) direct form with chained adders (linear delay) and (2) transposed form with pipelined adders (unit delay per stage).

Different configurations will be used in the testbench to instantiate and verify the three architectures, allowing comparison of their behavior under the same stimuli.
