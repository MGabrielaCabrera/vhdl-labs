## Lab description
Counts the number of leading ones in a binary input vector only using combinational logic.

## Some comments
This lab could have been implemented easily using a sequential process with registered flip-flops. However, I intentionally chose to design it using purely combinational logic (without a clocked process) as a learning exercise.

With a fully combinational approach, the propagation delay occurs through a logic chain, which can become long depending on the input width.

For clarification: a generate statement does not execute over time like a software loop. Instead, it instructs the synthesizer to replicate hardware structures multiple times with different indices. In hardware, this results in something like:

'''
array(0) → XOR → XOR → XOR → ...
'''

This creates a long combinational path, which may lead to critical timing issues.
Some improved alternatives to implement this lab are:

- Use a combinational process (no clock, no registers) to describe the logic more clearly while keeping the same hardware behavior.
- Use a multi-stage tree structure to reduce the length of the critical path and improve performance, especially for large input widths.
