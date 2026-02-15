#!/bin/bash
# Source module initialization
if [ -f /etc/profile.d/modules.sh ]; then
  . /etc/profile.d/modules.sh
elif [ -f /usr/share/modules/init/bash ]; then
  . /usr/share/modules/init/bash
fi

# Load modules as per agent.md
module load pulp/bender
module load cadence/xcelium

# Fallback path if module load fails check
if ! command -v xrun &> /dev/null; then
    export PATH=/opt/tools/cadence/XCELIUM2509/tools/bin:$PATH
fi

# License setup (derived from user's lmstat output)
export CDS_LIC_FILE=5280@license-server
export LM_LICENSE_FILE=5280@license-server

ROOT="/work/uge/work/axi_qspi"
xrun -64 -sv -access +r -timescale 1ns/1ps \
    "+define+TARGET_SIMULATION" \
    "+define+TARGET_XCELIUM" \
    "+define+USE_STD_SPI_MODEL" \
    "+incdir+$ROOT/deps/axi/include" \
    "$ROOT/src/axi_qspi_regs_pkg.sv" \
    "$ROOT/src/axi_qspi_regs.sv" \
    "$ROOT/src/spi_flash_model.sv" \
    "$ROOT/src/spi_controller.sv" \
    "$ROOT/src/axi_qspi_controller.sv" \
    "$ROOT/tb/tb_axi_qspi_controller.sv" \
    -run -exit
