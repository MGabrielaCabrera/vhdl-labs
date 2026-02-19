## Lab description
Counts the number of leading ones in a binary input vector only using combinational logic.

## Some comments
This lab could have been implemented easily using a sequential process with registered flip-flops. However, I intentionally chose to design it using purely combinational logic (without a clocked process) as a learning exercise.

There are two architectures for the same entity with the aim of practicing the use of configurations: **rtl** and **behavioral**.

### RTL architecture
With a fully combinational approach, the propagation delay occurs through a logic chain, which can become long depending on the input width.

For clarification: a generate statement does not execute over time like a software loop. Instead, it instructs the synthesizer to replicate hardware structures multiple times with different indices. In hardware, this results in something like:

'''
array(0) → XOR → XOR → XOR → ...
'''

This creates a long combinational path, which may lead to critical timing issues.

### Behavioral Architecture
This approach is much simpler and is still purely combinational because the process does not use a clock in its execution.

## Simulation
The created testbench (TB) takes the stimulus and the expected responses from a `.txt` file, raising exceptions if the results do not match the expected values.

I use GHDL through MSYS2 and GTKWave to display the waveforms.

Compilation and simulation can be executed using the `run.sh` file.