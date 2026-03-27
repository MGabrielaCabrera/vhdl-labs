# VHDL Labs

Hands-on VHDL lab with small RTL designs and testbenches, focused on digital design and simulation.

Each project targets a specific set of hardware description and verification concepts, from basic
combinational logic up to bus-connected peripherals.

---

## Projects

### `sequences_detector`
A Mealy FSM that detects three overlapping-free binary sequences (`"1110"`, `"1011"`, `"001"`) from a serial input stream, asserting a flag and incrementing a 32-bit counter on each match. Implemented with one-hot encoding via a synthesis attribute.

**Concepts:** FSM design (Mealy vs. Moore), one-hot state encoding, synchronous outputs,
VHDL attributes.

---

### `leading_ones_counter_comb`
Counts the number of leading ones in a binary vector using purely combinational logic, intentionally avoiding clocked processes as a learning exercise. Two architectures (`rtl` and `behavioral`) are provided for the same entity, practicing the use of VHDL configurations.

**Concepts:** Combinational logic design, `generate` statements and their hardware implications, VHDL configurations, file-driven testbenches.

---

### `fir_filter_with_fixed_and_programmed_coeff`
A parameterizable FIR filter with two alternative architectures derived from the reference
structures in *Circuit Design with VHDL* (Pedroni): a direct-form chain of adders and a pipelined transposed form. Coefficients are initially fixed, then extended to support runtime programming through a dedicated write interface.

**Concepts:** FIR filter architectures (direct vs. transposed), pipelining and critical path,
VHDL packages (shared types and constants), runtime-programmable interfaces, VHDL configurations, GHDL + GTKWave simulation flow.

---

### `axi_lite_fir_dsp_peripheral`
A synthesizable AXI-Lite slave peripheral that controls an external FIR DSP module through
memory-mapped registers and a control FSM. The peripheral bridges a processor to the DSP,
handling configuration, control, and status interactions. A later phase will extend the design with DMA or AXI-Stream interfaces for continuous streaming workloads.

This project will also serve as the starting point for reviewing **SystemVerilog for verification**, with the goal of developing a SV-based testbench environment for the peripheral.

**Concepts:** AXI-Lite protocol, memory-mapped register banks, control FSM design, processor–
peripheral bridging, modular RTL architecture. *(Upcoming: SV verification environment,
constrained-random stimulus, assertions.)*