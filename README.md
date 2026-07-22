# AXI QSPI Controller

A high-performance AXI4-to-QSPI bridge designed for interfacing with Quad-SPI flash memory devices. This controller supports both direct register-based access for configuration/commands and a memory-mapped mode for efficient Execute-In-Place (XIP) operations.

## Features

-   **AXI4 Slave Interface**: Configurable data and address widths (default 32-bit).
-   **Dual Operation Modes**:
    -   **Register Access Mode**: Direct control over SPI commands, address, and data via memory-mapped registers.
    -   **Memory Mapped Mode**: Maps AXI read transactions directly to SPI flash read commands (XIP) with automatic address translation.
-   **Multi-Chip Select**: Supports up to 4 Chip Selects (CS0-CS3) with configurable base addresses and masks.
-   **Auto-Initialization**: Optional sequence to automatically configure flash devices (e.g., Enable Quad Mode) upon reset.
-   **FIFO Buffer**: Internal TX and RX FIFOs for data buffering.
-   **Fail-Fast Verification**: Robust SystemVerilog testbench with immediate failure reporting.

## Directory Structure

```text
├── src/                # SystemVerilog RTL sources and RDL register definitions
├── tb/                 # SystemVerilog Testbench and C++ wrappers
├── doc/                # Documentation (Datasheet, generated HTML)
├── deps/               # External dependencies (e.g., PULP AXI) managed by Bender
├── .github/workflows/  # CI/CD Workflows
├── Bender.yml          # Dependency management configuration
├── Makefile            # Build and simulation scripts
├── LICENSE             # Solderpad Hardware License v2.1
└── run_opensource.sh   # Xcelium simulation script
```

## Prerequisites

-   **Verilator**: v5.022 or later (Support for `--timing` and SystemVerilog 2017 features).
-   **Python 3**: For PeakRDL register generation.
-   **Bender**: For dependency management ([Installation Guide](https://github.com/pulp-platform/bender)).
-   **Xcelium** (Optional): For proprietary simulation flows.

## Getting Started

### 1. Setup

Clone the repository and fetch dependencies:

```bash
git clone https://github.com/persimmonsai/axi-qspi.git
cd axi-qspi
bender update
```

### 2. Generate Registers

The register map is defined in `src/axi_qspi_regs.rdl`. Use the Makefile to generate the SystemVerilog RTL and C headers:

```bash
make gen      # Generates RTL in src/generated/
make headers  # Generates C headers in sw/include/
make docs     # Generates HTML documentation in doc/rdl/
```

### 3. Run Simulation

The project includes a Verilator-based simulation flow.

```bash
make verilator
```

This command will:
1.  Check/Install Python dependencies (PeakRDL).
2.  Generate register RTL.
3.  Compile the RTL and Testbench using Verilator.
4.  Run the simulation.

Success output:
```text
[TB] Post-Init Read Success!
[TB] Test 9 Complete.
- tb/tb_axi_qspi_controller.sv:1236: Verilog $finish
```

## Regression (Xcelium)

`tb/` contains three separate testbenches, each pairing the real controller
against a different flash target. They are independent simulations, not one
combined regression. Each has its own Makefile target that asks Bender for
the RTL file list (`bender script flist`, no per-file maintenance in the
Makefile itself) and only hand-adds the one thing Bender deliberately
doesn't resolve for you: which of this package's own testbenches is the top
for that run (see the Makefile's own "Regression (Xcelium, RTL sourced via
Bender)" section for why testbenches aren't just pulled in via `-t test` the
same way). Requires `xrun` on `PATH` (e.g. `module load cadence/xcelium`), a
valid `CDS_LIC_FILE`/`LM_LICENSE_FILE`, and Bender itself; both are
auto-detected from the Persimmons server install, or override via
`XCELIUM_HOME=`/`BENDER=`.

```bash
make regress            # all three, one after another
make regress-generic    # 1. tb_axi_qspi_controller.sv vs spi_flash_model.sv
make regress-fpga       # 2. tb_axi_qspi_controller_fpga_synt.sv vs spi_flash_model_fpga_synt.sv
make regress-s25hs01gt  # 3. tb_axi_qspi_controller_s25hs01gt.sv vs the real Infineon model
make regress-clean      # wipe work-regress/
```

Each target compiles+elaborates+runs in one shot (`xrun ... -run -exit`)
into its own subdirectory under `work-regress/`, so they never share (or
corrupt) each other's Xcelium snapshot.

### 1. `regress-generic`

The main regression: 19 tests covering Standard/Fast/Dual/Quad reads, XIP,
multi-CS, partial write strobes, mode-byte (`0xEB`/`0xBB`) reads, and manual
writes, all against this package's own simplified behavioral flash model.
Look for one `[TB] Test N ... PASSED` line per test and no `FAILED`/`$fatal`.

### 2. `regress-fpga`

Integration test for the FPGA-synthesizable flash model (the one actually
used on-FPGA), driven through the real controller via AXI -- covers RDID,
Standard/Fast/Quad reads, a multi-beat burst, a manual Page Program +
memory-mapped read-back, and Sector Erase (placed last: with the small test
memory this testbench uses, an erase wipes the whole address space). This
model instantiates Xilinx's `xpm_memory_spram` directly, so the Makefile
also compiles in a Vivado install's own `xpm_memory.sv` (`XPM_DIR`, override
if your Vivado lives elsewhere). (A standalone bit-bang testbench used to
cover this same model directly, with no controller in the loop -- retired
once every one of its checks was ported in here, so there'd be only one
FPGA-model testbench to maintain.)

### 3. `regress-s25hs01gt`

Protocol-compatibility smoke test against Infineon/Cypress's own behavioral
model (`vendor/s25hs01gtRel/`, ~17k lines) -- RDID, Standard/Fast/Quad/Dual
reads (plain and mode-byte), manual and XIP writes, 4-byte addressing, and a
4-beat burst. Sourced via Bender's own `flash_s25hs01gt` target. Sector
Erase is expected to fail (`EXPECTED (known vendor model defect)`) -- see
`doc/s25hs01gt_verification_tracking.md` for why; that is not a regression.

## Continuous Integration

A GitHub Actions workflow (`.github/workflows/verilator.yml`) is configured to automatically run the Verilator verification suite on every push and pull request to the `main` branch.

## Documentation

-   **Datasheet**: See [doc/datasheet.md](doc/datasheet.md) for detailed signal descriptions and register maps.
-   **Register Map**: HTML documentation is generated in `doc/rdl/` after running `make docs`.

## FPGA Flash Emulation Model

`src/spi_flash_model_fpga_synt.sv` (module `spi_flash_model_fpga_synt`) is
synthesizable by Vivado and can be used as an on-FPGA SPI/QSPI flash target.
It is a separate model from `src/spi_flash_model.sv` (the behavioral,
associative-array model used by this package's own testbench) — the fixed
memory defaults to 1 MiB and aliases larger flash addresses into that range.
Configure it with:

-   `MEM_ADDR_WIDTH`: byte-memory address width (default `20`).
-   `INIT_FILE`: optional `$readmemh` image used for RAM initialization.
-   `PROGRAM_BUSY_CYCLES` and `STATUS_BUSY_CYCLES`: busy duration measured in
    incoming SCK edges.

The model supports standard, dual-output, quad-output, QPI, 3-byte and 4-byte
reads, page program, status/ID/SFDP access, and serialized sector/block/chip
erase. DTR opcodes are accepted but transfer data as SDR because portable FPGA
logic cannot update one state machine on both SCK edges.

## License

This project is licensed under the Solderpad Hardware License v2.1. See [LICENSE](LICENSE) for details.
