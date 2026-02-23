## Lab description
This test consists of designing and evaluating a VHDL implementation of a Finite Impulse Response (FIR) filter that supports both fixed and programmable coefficients, selectable through a boolean generic constant. The design must include three alternative architectures: (1) direct form with chained adders (linear delay), (2) direct form with tree-structured adders (logarithmic delay), and (3) transposed form with pipelined adders (unit delay per stage).

Different configurations will be used in the testbench to instantiate and verify the three architectures, allowing comparison of their behavior under the same stimuli.
