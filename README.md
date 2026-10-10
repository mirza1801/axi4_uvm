# AXI4 UVM Verification Project

This repository contains a basic SystemVerilog/UVM testbench for a simple AXI4 memory-mapped slave. The project is being developed incrementally: the current goal is to run and understand the basic write/read path, then expand protocol coverage.

## Project goal

The testbench generates AXI4 transactions, drives them through an interface, observes completed bus transactions, and checks read data against a reference-memory model in the scoreboard.

The intended transaction flow is:

```text
Sequence → Sequencer → Driver → AXI Interface → DUT → Monitor → Scoreboard
```

## Verification architecture

- **Sequence** creates directed and constrained-random AXI transactions.
- **Sequencer** passes sequence items to the driver.
- **Driver** drives the AXI signals and collects responses.
- **Monitor** observes handshakes and publishes completed transactions.
- **Scoreboard** keeps reference memory and compares read data.
- **Agent** contains the sequencer, driver, and monitor.
- **Environment** builds the agent and scoreboard and connects the monitor analysis port.
- **Test** builds the environment, starts the sequence, and controls the UVM objection.
- **Top-level testbench** creates the clock and reset, configures the virtual interface, instantiates the DUT, and starts UVM.

## Current status

The EDA Playground milestone exercises a basic single-beat write followed by a read from the same address. The directed example writes data `50` to address `100`, then reads it back. The scoreboard reports the expected and observed values.

The repository includes the simple memory-slave DUT (`axi_mem_slave.sv`) and the environment file is named `axi_env.sv`, matching the include in `tb_top.sv`.

The screenshot below shows the EDA Playground result.

![Basic AXI4 UVM simulation result](docs/axi4_uvm_basic_test_result.png)

## Project files

- `tb_top.sv` — Top module, clock/reset, virtual-interface setup, DUT instance, and UVM startup. It includes the UVM testbench source files.
- `axi_if.sv` — AXI interface signals.
- `axi_mem_slave.sv` — Simple byte-addressable memory slave used as the DUT.
- `axi_txn.sv` — AXI transaction item.
- `axi_sequence.sv` — Directed and constrained-random stimulus.
- `axi_sequencer.sv` — UVM sequencer.
- `axi_driver.sv` — Drives AXI requests and accepts responses.
- `axi_monitor.sv` — Observes AXI handshakes and publishes transactions.
- `axi_scoreboard.sv` — Reference-memory model and read-data checks.
- `axi_agent.sv` — Groups the sequencer, driver, and monitor.
- `axi_env.sv` — Builds and connects the agent and scoreboard.
- `axi_test.sv` — Creates the environment and starts the sequence.
- `run_vcs.sh` — Compiles and runs the UVM test with Synopsys VCS.
- `docs/axi4_uvm_basic_test_result.png` — EDA Playground result screenshot.

## Run with Synopsys VCS

The project includes `run_vcs.sh`, which compiles the testbench with VCS and runs the `axi_test` UVM test. Run it from the repository root on a machine with Synopsys VCS and UVM support:

```bash
command -v vcs
vcs -ID
./run_vcs.sh
```

The script compiles `tb_top.sv` and `axi_mem_slave.sv`. The UVM source files are included by `tb_top.sv`, so they are not listed separately. Extra simulator arguments can be passed after the script name, for example:

```bash
./run_vcs.sh +UVM_VERBOSITY=UVM_HIGH
```

The script uses the VCS UVM 1.2 option. If the installed VCS setup uses another UVM version, update the option in `run_vcs.sh`.

## Current limitations

This is a basic starting point, not a complete AXI4 verification environment. Features still to implement and verify include:

- Full FIXED, INCR, and WRAP burst behavior.
- Multiple outstanding transactions and response ordering.
- Complete ID tracking and out-of-order response checks.
- Narrow and unaligned transfers, complete `WSTRB` behavior, and 4 KB boundary checks.
- Broader response/error testing.
- Protocol assertions and functional coverage.
- Larger constrained-random regressions.

The memory slave is a simple educational DUT and does not represent a production AXI4 slave.

## Next steps

1. Run the basic test with Synopsys VCS.
2. Add directed tests for more addresses, data values, and byte strobes.
3. Expand burst handling and scoreboard checks.
4. Add assertions, functional coverage, and regression tests.

## References

- [Arm AMBA AXI and ACE Protocol Specification](https://developer.arm.com/documentation/ihi0022/latest/)
- [AXI Protocol — VLSI Verify](https://vlsiverify.com/protocols/axi/)
