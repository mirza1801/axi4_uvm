# AXI4 UVM Verification Environment

This repository contains a SystemVerilog/UVM verification environment for an AXI4 memory-mapped slave.

## Verification flow

The testbench:

1. Generates a 10-time-unit clock and applies reset.
2. Passes the virtual AXI interface through the UVM configuration database.
3. Starts `axi_test`.
4. Runs `axi_sequence`, which generates:
   - One fully constrained-random transaction.
   - A directed single-beat write to address `100` with data `50`.
   - A directed single-beat read from address `100`.
5. Sends monitored transactions to the scoreboard for checking.

## Project files

- `tb_top.sv` — Top-level testbench, clock, reset, interface, DUT instance, and UVM startup.
- `axi_if.sv` — AXI interface and signals.
- `axi_txn.sv` — AXI transaction class.
- `axi_sequence.sv` — Random and directed stimulus.
- `axi_sequencer.sv` — UVM sequencer.
- `axi_driver.sv` — Drives AXI transactions onto the interface.
- `axi_monitor.sv` — Observes AXI activity and publishes transactions.
- `axi_scoreboard.sv` — Receives monitored transactions for checking.
- `axi_agent.sv` — Contains the sequencer, driver, and monitor.
- `axi.env.sv` — Builds and connects the agent and scoreboard.
- `axi_test.sv` — Creates the environment and starts the sequence.

## Running the simulation

Use a SystemVerilog simulator with UVM support, such as Synopsys VCS, Questa, or Xcelium. For VCS, an example command is:

```bash
vcs -full64 -sverilog -ntb_opts uvm-1.2 \
  axi_if.sv axi_txn.sv axi_sequence.sv axi_sequencer.sv \
  axi_driver.sv axi_monitor.sv axi_scoreboard.sv axi_agent.sv \
  axi.env.sv axi_test.sv tb_top.sv axi_mem_slave.sv \
  -o simv

./simv +UVM_TESTNAME=axi_test
```

The `axi_mem_slave.sv` file represents the DUT and must be available in the simulation file list. It is not included in this repository upload.

## Important filename note

`tb_top.sv` currently includes `axi_env.sv`, while the environment file in this repository is named `axi.env.sv`. Rename the file or update the include statement before compiling.
