# Makefile for AXI SPI Master Register Generation

PYTHON ?= python3
VENV ?= .venv
PEAKRDL = $(VENV)/bin/peakrdl

.PHONY: all clean venv gen docs headers verilator

all: gen

# Create Virtual Environment and Install PeakRDL
venv: $(VENV)/bin/activate

$(VENV)/bin/activate:
	$(PYTHON) -m venv $(VENV)
	. $(VENV)/bin/activate && pip install --upgrade pip
	. $(VENV)/bin/activate && pip install peakrdl peakrdl-regblock peakrdl-html peakrdl-cheader

# Generate SystemVerilog from RDL
gen: venv src/axi_qspi_regs.rdl
	mkdir -p src/generated
	$(PEAKRDL) regblock src/axi_qspi_regs.rdl -o src/generated --cpuif axi4-lite-flat
	@echo "RTL Generation Complete."

# Generate HTML Documentation
docs: venv src/axi_qspi_regs.rdl
	mkdir -p doc/rdl
	$(PEAKRDL) html src/axi_qspi_regs.rdl -o doc/rdl
	@echo "Documentation Generated in doc/rdl"

# Generate C Headers
headers: venv src/axi_qspi_regs.rdl
	mkdir -p sw/include
	$(PEAKRDL) c-header src/axi_qspi_regs.rdl -o sw/include/regs.h
	@echo "C Headers Generated in sw/include"

# Verilator Simulation
verilator: gen
	mkdir -p build/verilator_obj
	verilator --binary -j 0 --trace --top-module tb_axi_qspi_controller \
		-Wno-TIMESCALEMOD \
		-Wno-INITIALDLY \
		-Wno-MULTIDRIVEN \
        -Wno-WIDTHEXPAND \
        -Wno-WIDTHTRUNC \
        -Wno-CASEINCOMPLETE \
        -Wno-UNOPTFLAT \
        +define+USE_STD_SPI_MODEL \
        +incdir+deps/axi/include \
		src/axi_qspi_regs_pkg.sv \
		src/generated/axi_qspi_regs.sv \
		src/spi_flash_model.sv \
		src/spi_controller.sv \
		src/axi_qspi_controller.sv \
		tb/tb_axi_qspi_controller.sv \
		--Mdir build/verilator_obj
	./build/verilator_obj/Vtb_axi_qspi_controller +trace

clean:
	rm -rf src/generated
	rm -rf $(VENV)
	rm -rf build
