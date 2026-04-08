⁸## Lab description
This project implements a synthesizable AXI-Lite slave peripheral in VHDL designed to control an external FIR DSP module through memory-mapped registers and dedicated control signals. The peripheral acts as a bridge between a processor and the DSP, translating AXI transactions into configuration, control, and status interactions. It includes an AXI interface, a register bank, and a control FSM that manages DSP operation, synchronization, and safe coefficient updates.

In the initial phase, data and coefficients are transferred to the DSP through internal register-driven signals, prioritizing simplicity and architectural clarity. A later phase will extend the design with high-throughput data paths using DMA or AXI-Stream interfaces to support continuous streaming workloads. The modular structure allows the DSP block to be replaced or upgraded independently while keeping the processor interface stable.

**The spec can be found in doc/AXI-Lite FIR DSP Peripheral - Design Spec.pdf**

## Simulation
All modules in this project have been individually simulated using VHDL testbenches with VHDL assertions (simple test approach). The detailed results and waveforms are documented in the verification document located in the `doc/` folder.

### Top-Level Simulation (SV)

An additional, more comprehensive testbench has been developed for the main design, `top_level_wrapper_tb.sv`, written in SystemVerilog. This testbench was created with the dual purpose of validating the full design and serving as a practical introduction to advanced SystemVerilog verification concepts, including:

- Modules, interfaces and modports
- Clocking blocks
- Concurrent and procedural assertions 
- Macros

This simulation achieves better timing accuracy than the VHDL counterpart by leveraging SystemVerilog's scheduling regions:

- Active region, used for DUT execution.
- Observed region, used for assertion evaluation.
- Reactive region,  used for testbench stimulus (prepone sampling), ensuring race-condition-free interaction between the testbench and the DUT.

### Running the SV Simulation

The simulation is run using ModelSim (note: the free version has limitations:  `program` blocks are not supported; this was worked around using `module` + clocking blocks).

A `run.do` script is provided to automate the simulation. To launch it, open a Windows command prompt and run:

```cmd
vsim -do run.do
```


**The simulation results can be found in AXI-Lite FIR DSP Peripheral - Verification.pdf**

