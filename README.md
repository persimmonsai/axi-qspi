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

## Continuous Integration

A GitHub Actions workflow (`.github/workflows/verilator.yml`) is configured to automatically run the Verilator verification suite on every push and pull request to the `main` branch.

## Documentation

-   **Datasheet**: See [doc/datasheet.md](doc/datasheet.md) for detailed signal descriptions and register maps.
-   **Register Map**: HTML documentation is generated in `doc/rdl/` after running `make docs`.

## License

This project is licensed under the Solderpad Hardware License v2.1. See [LICENSE](LICENSE) for details.
