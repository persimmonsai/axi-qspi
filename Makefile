# Makefile for AXI SPI Master Register Generation

PYTHON ?= python3
VENV ?= .venv
PEAKRDL = $(VENV)/bin/peakrdl

.PHONY: all clean venv gen docs headers verilator \
	regress regress-generic regress-fpga regress-s25hs01gt regress-clean

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
		src/axi_qspi_regs.sv \
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

# =============================================================================
# Regression (Xcelium, RTL sourced via Bender)
# =============================================================================
# Each target below asks Bender for the RTL/model file list for its own
# target combo (`bender script flist`, plain one-path-per-line output, no
# manual per-file maintenance here) and only hand-appends the ONE thing
# Bender deliberately does not resolve: this package's own testbench for
# that scenario. Testbenches stay out of the Bender-driven list on purpose
# -- pulling them in via `-t test` would also drag in every dependency's
# own bundled test sources (axi/common_cells/common_verification all ship
# their own tb_*.sv under `target: test`), which is pure noise here and
# would need its own grep -v filter list to undo. See README.md's
# "Regression (Xcelium)" section for what each of these four testbenches
# actually covers and what a clean run looks like.
#
# Auto-detected tool locations, same convention as
# chiplet-lunella/test_rv64/Makefile: explicit env var wins, then the
# Persimmons server install, then bare PATH lookup.
_BENDER_SERVER := /opt/tools/pulp/bender/persimmons/bin/bender
ifndef BENDER
  ifneq ($(wildcard $(_BENDER_SERVER)),)
    BENDER := $(_BENDER_SERVER)
  else
    BENDER := bender
  endif
endif

_XCELIUM_SERVER := /opt/tools/cadence/XCELIUM2509
ifndef XCELIUM_HOME
  ifneq ($(wildcard $(_XCELIUM_SERVER)/tools/bin/xrun),)
    XCELIUM_HOME := $(_XCELIUM_SERVER)
  endif
endif
ifneq ($(XCELIUM_HOME),)
  export PATH := $(XCELIUM_HOME)/tools/bin:$(PATH)
endif
LM_LICENSE_FILE ?= 5280@license-server
export LM_LICENSE_FILE

# Vivado's xpm_memory.sv -- needed only by the two FPGA-flash-model targets
# below (src/spi_flash_model_fpga_synt.sv instantiates xpm_memory_spram
# directly). Not a Bender dependency: it comes from the local Vivado
# install, not a vendored/tracked source, same reasoning as
# test_rv64/Makefile's own XPM_DIR/XILINX_UNISIM_DIR.
XPM_DIR ?= /opt/tools/Xilinx/2025.2/data/ip/xpm/xpm_memory/hdl

REGRESS_DIR := work-regress
# `-t simulation` pulls in axi's own transitive deps (common_cells,
# common_verification, tech_cells_generic), not just axi itself -- each of
# their own `.svh` headers (assertions/registers macros) needs its own
# +incdir+, or affected files fail to parse (a missing `` `include `` target
# does not always show up as a clean "cannot open include file" error --
# confirmed via bisection that it can instead desync the parser on
# whatever file happens to compile next, several files later).
XRUN_COMMON := -64 -sv -access +r -timescale 1ns/1ps +define+TARGET_SIMULATION +define+TARGET_XCELIUM \
	"+incdir+$(CURDIR)/deps/axi/include" \
	"+incdir+$(CURDIR)/deps/common_cells/include"

regress: regress-generic regress-fpga regress-s25hs01gt

# All targets pin `-top` explicitly: without it, xrun auto-elaborates
# every uninstantiated top-level module it finds in the compiled library --
# harmless-looking on its own package, but `-t simulation` pulls in axi's
# whole transitive dependency tree (common_cells etc.), several of whose
# modules (axi_lfsr, the deprecated find_first_one, ...) are standalone/
# uninstantiated from axi_qspi's own hierarchy and don't actually
# elaborate cleanly in isolation (e.g. find_first_one's default generic
# width blows up its own for-generate). `-top` constrains elaboration to
# only the one hierarchy actually under test.

# 1. tb_axi_qspi_controller.sv vs src/spi_flash_model.sv (main regression)
regress-generic:
	mkdir -p $(REGRESS_DIR)/generic
	cd $(REGRESS_DIR)/generic && $(BENDER) script flist -t simulation > files.f
	cd $(REGRESS_DIR)/generic && xrun $(XRUN_COMMON) +define+USE_STD_SPI_MODEL \
		-f files.f \
		"$(CURDIR)/tb/tb_axi_qspi_controller.sv" \
		-top tb_axi_qspi_controller \
		-run -exit

# 2. tb_axi_qspi_controller_fpga_synt.sv vs src/spi_flash_model_fpga_synt.sv
#    (integration test through the real controller -- RDID, Standard/Fast/
#    Quad reads, a multi-beat burst, manual Page Program + memory-mapped
#    read-back, and Sector Erase, all through the controller's own AXI/
#    manual-register interface. tb_spi_flash_model_fpga_synt.sv's standalone
#    bit-bang harness used to cover this same model directly -- retired
#    once every one of its checks (including RDID and Sector Erase) was
#    ported in here, so there'd be only one FPGA-model testbench to
#    maintain instead of two.)
regress-fpga:
	mkdir -p $(REGRESS_DIR)/fpga
	cp tb/tb_fpga_synt_preload.mem $(REGRESS_DIR)/fpga/
	cd $(REGRESS_DIR)/fpga && $(BENDER) script flist -t simulation -t fpga -t tech_cells_generic_exclude_deprecated > files.f
	cd $(REGRESS_DIR)/fpga && xrun $(XRUN_COMMON) \
		"$(XPM_DIR)/xpm_memory.sv" \
		-f files.f \
		"$(CURDIR)/tb/tb_axi_qspi_controller_fpga_synt.sv" \
		-top tb_axi_qspi_controller_fpga_synt \
		-run -exit

# 3. tb_axi_qspi_controller_s25hs01gt.sv vs the real Infineon S25HS01GT model
regress-s25hs01gt:
	mkdir -p $(REGRESS_DIR)/s25hs01gt
	cp vendor/s25hs01gtRel/s25hs01gt.mem vendor/s25hs01gtRel/s25hs01gtOTP.mem $(REGRESS_DIR)/s25hs01gt/
	cd $(REGRESS_DIR)/s25hs01gt && $(BENDER) script flist -t simulation -t flash_s25hs01gt > files.f
	cd $(REGRESS_DIR)/s25hs01gt && xrun $(XRUN_COMMON) \
		-f files.f \
		"$(CURDIR)/tb/tb_axi_qspi_controller_s25hs01gt.sv" \
		-top tb_axi_qspi_controller_s25hs01gt \
		-run -exit

regress-clean:
	rm -rf $(REGRESS_DIR)
