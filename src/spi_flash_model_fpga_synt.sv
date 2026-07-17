`timescale 1ns / 1ps

// Synthesizable SPI/QSPI flash model intended for FPGA-based emulation.
//
// The model deliberately uses only a fixed-size memory, one SCK edge, and
// counters.  Flash addresses alias into MEM_ADDR_WIDTH bits.  Long erase
// operations are performed one byte per SCK edge; software polling RDSR
// supplies the clocks needed to complete them.
//
// No `inout` anywhere (this connects to a QSPI controller inside the
// SAME FPGA fabric, not a real physical pad -- a genuine bidirectional
// net between two internal RTL blocks is only legal at a real chip I/O
// buffer). Each quad-I/O line is split into a plain `_i` (what the
// controller is currently driving, always valid) and `_o` (what this
// model wants to drive back); the consumer selects between them using
// the controller's own output-enable -- see
// fpga_syn/rtl/spi_flash_model_fpga_shell.sv (chiplet-lunella) for the
// placeholder this file is a drop-in replacement for, and that file's
// own header for the full rationale.
module spi_flash_model_fpga_synt #(
    parameter integer MEM_ADDR_WIDTH = 20,
    parameter         INIT_FILE      = "",
    parameter integer PROGRAM_BUSY_CYCLES = 16,
    parameter integer STATUS_BUSY_CYCLES  = 8
) (
    input wire SCK,
    input wire CSNeg,
    input wire RESETNeg,

    input  wire SI_i,
    output wire SI_o,  // IO0
    input  wire SO_i,
    output wire SO_o,  // IO1
    input  wire WPNeg_i,
    output wire WPNeg_o,  // IO2
    input  wire IO3_RESETNeg_i,
    output wire IO3_RESETNeg_o  // IO3
);

  localparam integer MEM_DEPTH = (1 << MEM_ADDR_WIDTH);
  localparam integer BUSY_WIDTH = 16;
  localparam logic [MEM_ADDR_WIDTH:0] SECTOR_ERASE_COUNT =
      (MEM_DEPTH < 4096) ? MEM_DEPTH : 4096;
  localparam logic [MEM_ADDR_WIDTH:0] BLOCK_ERASE_COUNT =
      (MEM_DEPTH < 65536) ? MEM_DEPTH : 65536;

  localparam logic [7:0] CMD_PROGRAM    = 8'h02;
  localparam logic [7:0] CMD_SECTOR_ER  = 8'h20;
  localparam logic [7:0] CMD_BLOCK_ER   = 8'hd8;
  localparam logic [7:0] CMD_RDSR       = 8'h05;
  localparam logic [7:0] CMD_WRSR       = 8'h01;
  localparam logic [7:0] CMD_WREN       = 8'h06;
  localparam logic [7:0] CMD_RDID       = 8'h9f;
  localparam logic [7:0] CMD_SFDP       = 8'h5a;

  typedef enum logic [2:0] {
    ST_CMD,
    ST_ADDR,
    ST_DUMMY,
    ST_DATA_TX,
    ST_DATA_RX,
    ST_IGNORE
  } flash_state_t;

  typedef enum logic [1:0] {
    MODE_SPI,
    MODE_DUAL,
    MODE_QUAD
  } spi_mode_t;

  // Real Xilinx distributed-RAM (LUTRAM) primitive (xpm_memory_spram),
  // not an inferred array -- see the instantiation below for the full
  // rationale (in particular why distributed, not block/UltraRAM). These
  // wires are driven combinationally further down (mem_we/mem_waddr/
  // mem_wdata mirror the exact conditions that used to gate `mem[x] <= y`
  // directly; mem_read_addr replaces the old `read_mem()` function's
  // argument), and mem_douta is the primitive's own combinational
  // (zero-latency) read output.
  logic                      mem_we;
  logic [MEM_ADDR_WIDTH-1:0] mem_waddr;
  logic [7:0]                mem_wdata;
  logic [MEM_ADDR_WIDTH-1:0] mem_read_addr;
  logic [MEM_ADDR_WIDTH-1:0] mem_addra;
  logic [7:0]                mem_douta;

  // Persistent flash state.  These names are intentionally retained because
  // existing emulation testbenches commonly inspect them hierarchically.
  logic [7:0] status_reg;
  logic       addr_mode_4b;
  logic       qpi_active;
  logic       reset_enable;

  logic [BUSY_WIDTH-1:0] busy_count;
  logic                  erase_active;
  logic [MEM_ADDR_WIDTH-1:0] erase_addr;
  logic [MEM_ADDR_WIDTH:0]   erase_count;
  wire busy = erase_active || (busy_count != 0);

  flash_state_t state;
  spi_mode_t    current_mode;
  logic [7:0]   cmd;
  logic [7:0]   shift_reg;
  logic [31:0]  addr;
  logic [5:0]   bit_count;
  logic [5:0]   addr_bits;
  logic [4:0]   dummy_count;
  logic [7:0]   tx_byte;
  logic [1:0]   id_index;
  logic         is_rdid;
  logic         is_sfdp_read;

  wire io0_in = SI_i;
  wire io1_in = SO_i;
  wire io2_in = WPNeg_i;
  wire io3_in = IO3_RESETNeg_i;

  wire [2:0] input_lanes  = qpi_active ? 3'd4 : 3'd1;
  wire [2:0] output_lanes = (qpi_active || current_mode == MODE_QUAD) ? 3'd4 :
                            (current_mode == MODE_DUAL) ? 3'd2 : 3'd1;
  wire [3:0] input_value  = qpi_active ? {io3_in, io2_in, io1_in, io0_in} :
                                         {3'b000, io0_in};
  wire [7:0] shifted_value = qpi_active ? {shift_reg[3:0], input_value} :
                                         {shift_reg[6:0], io0_in};
  wire [31:0] shifted_addr = (addr << input_lanes) | input_value;
  wire command_complete = (state == ST_CMD) &&
                          ((bit_count + input_lanes) >= 8);
  wire receive_complete = (state == ST_DATA_RX) &&
                          ((bit_count + input_lanes) >= 8);

  // Whether a read of address `a` should appear as 8'hff because it falls
  // inside an in-progress serialized erase (logically complete as soon as
  // it is accepted; the BRAM locations are then physically cleared at one
  // byte per later SCK) -- used to override mem_douta combinationally
  // rather than reading a plain array directly, since the real memory is
  // now the XPM primitive below.
  function automatic logic erase_shadows(input logic [31:0] a);
    logic [MEM_ADDR_WIDTH:0] read_index;
    begin
      read_index = {1'b0, a[MEM_ADDR_WIDTH-1:0]};
      erase_shadows = erase_active &&
          read_index >= {1'b0, erase_addr} &&
          read_index < ({1'b0, erase_addr} + erase_count);
    end
  endfunction

  function automatic logic [7:0] sfdp_byte(input logic [7:0] a);
    begin
      // Minimal valid SFDP header.  Unimplemented parameter bytes read 0xff.
      case (a)
        8'h00: sfdp_byte = 8'h53; // S
        8'h01: sfdp_byte = 8'h46; // F
        8'h02: sfdp_byte = 8'h44; // D
        8'h03: sfdp_byte = 8'h50; // P
        8'h04: sfdp_byte = 8'h06; // minor revision
        8'h05: sfdp_byte = 8'h01; // major revision
        8'h06: sfdp_byte = 8'h00; // one parameter header
        8'h07: sfdp_byte = 8'hff;
        default: sfdp_byte = 8'hff;
      endcase
    end
  endfunction

  function automatic logic command_has_address(input logic [7:0] c);
    begin
      case (c)
        8'h03, 8'h0b, 8'h3b, 8'h6b, 8'h02, 8'h20, 8'hd8,
        8'h0d, 8'hbd, 8'hed, 8'h13, 8'h0c, 8'h12, 8'h3c,
        8'h6c, 8'h5a: command_has_address = 1'b1;
        default:      command_has_address = 1'b0;
      endcase
    end
  endfunction

  function automatic logic command_is_4byte(input logic [7:0] c);
    begin
      case (c)
        8'h13, 8'h0c, 8'h12, 8'h3c, 8'h6c:
          command_is_4byte = 1'b1;
        default: command_is_4byte = 1'b0;
      endcase
    end
  endfunction

  initial begin
    state          = ST_CMD;
    current_mode   = MODE_SPI;
    cmd            = 0;
    shift_reg      = 0;
    addr           = 0;
    bit_count      = 0;
    addr_bits      = 24;
    dummy_count    = 0;
    tx_byte        = 8'hff;
    id_index       = 0;
    is_rdid        = 1'b0;
    is_sfdp_read   = 1'b0;
    // Memory content itself is no longer initialized here -- the XPM
    // primitive below is preloaded via its own real MEMORY_INIT_FILE
    // parameter (INIT_FILE, "none" meaning uninitialized/erased-per-BRAM-
    // default), same real mechanism VROM's own FPGA stand-in uses
    // (deps/anc-adapter/fpga/src/ln04lpp_s00_mc_vromp_hd_lvt_1024x64m8b2c1_fpga.v),
    // rather than a procedural fill loop / $readmemh racing a second
    // initialization source for the same memory (the real, confirmed
    // MULTI-MEM-INIT-SAME-HIERSIG synthesis error that motivated this
    // whole rewrite in the first place).
  end

  // Persistent state and the single memory write port.  Erases are serialized
  // so the array remains inferable as FPGA memory instead of a huge resettable
  // bank of flip-flops.
  always @(posedge SCK or negedge RESETNeg) begin
    if (!RESETNeg) begin
      status_reg   <= 8'h40;
      addr_mode_4b <= 1'b0;
      qpi_active   <= 1'b0;
      reset_enable <= 1'b0;
      busy_count   <= 0;
      erase_active <= 1'b0;
      erase_addr   <= 0;
      erase_count  <= 0;
    end else begin
      if (busy_count != 0)
        busy_count <= busy_count - 1'b1;

      if (erase_active) begin
        erase_addr <= erase_addr + 1'b1;
        erase_count <= erase_count - 1'b1;
        if (erase_count == 1)
          erase_active <= 1'b0;
      end

      if (command_complete) begin
        if (shifted_value == 8'h66) begin
          reset_enable <= 1'b1;
        end else if (shifted_value == 8'h99) begin
          if (reset_enable) begin
            status_reg   <= 8'h40;
            addr_mode_4b <= 1'b0;
            qpi_active   <= 1'b0;
            busy_count   <= 0;
            erase_active <= 1'b0;
          end
          reset_enable <= 1'b0;
        end else begin
          reset_enable <= 1'b0;
          case (shifted_value)
            CMD_WREN: if (!busy) status_reg[1] <= 1'b1;
            8'hb7:    if (!busy) addr_mode_4b <= 1'b1;
            8'he9:    if (!busy) addr_mode_4b <= 1'b0;
            8'h38:    if (!busy) qpi_active <= 1'b1;
            8'hff:    qpi_active <= 1'b0;
            8'hc7, 8'h60: begin
              if (status_reg[1] && !busy) begin
                erase_active <= (MEM_DEPTH > 1);
                erase_addr   <= 1;
                erase_count  <= MEM_DEPTH - 1;
                status_reg[1] <= 1'b0;
              end
            end
            default: begin end
          endcase
        end
      end

      // Addressed erase starts on the edge which receives the final address
      // bits.  Alignment matches 4 KiB sectors and 64 KiB blocks.
      if ((state == ST_ADDR) && ((bit_count + input_lanes) >= addr_bits) &&
          status_reg[1] && !busy) begin
        if (cmd == CMD_SECTOR_ER) begin
          erase_active <= (SECTOR_ERASE_COUNT > 1);
          erase_addr <= (shifted_addr & 32'hfffff000) + 1'b1;
          erase_count <= SECTOR_ERASE_COUNT - 1'b1;
          status_reg[1] <= 1'b0;
        end else if (cmd == CMD_BLOCK_ER) begin
          erase_active <= (BLOCK_ERASE_COUNT > 1);
          erase_addr <= (shifted_addr & 32'hffff0000) + 1'b1;
          erase_count <= BLOCK_ERASE_COUNT - 1'b1;
          status_reg[1] <= 1'b0;
        end
      end

      if (receive_complete) begin
        if (cmd == CMD_WRSR) begin
          if (status_reg[1] && !busy) begin
            status_reg[7:2] <= shifted_value[7:2];
            status_reg[1] <= 1'b0;
            busy_count <= STATUS_BUSY_CYCLES;
          end
        end else if ((cmd == CMD_PROGRAM || cmd == 8'h12) &&
                     status_reg[1] && !erase_active) begin
          busy_count <= PROGRAM_BUSY_CYCLES;
        end
      end
    end
  end

  // Real Xilinx distributed-RAM write port, driven combinationally.  Each term
  // below mirrors -- exactly, same priority order -- one of the `mem[x] <=
  // y` sites the sequential block above used to drive directly: erase
  // serialization, chip-erase's own immediate first-byte clear, sector/
  // block-erase-start's own first-byte clear, and program. All four are
  // mutually exclusive by construction (erase_active gates out new
  // command processing via ST_IGNORE, so an ongoing erase and a fresh
  // addressed-erase-start or program can never fire on the same edge; the
  // sequential block's own if/else-if structure already keeps the other
  // three exclusive too), so a plain priority list -- not full a priority
  // encoder -- is all that is needed. Reading the SAME registered state
  // the sequential block above reads (erase_active, command_complete,
  // shifted_value, state/bit_count/addr_bits, receive_complete, cmd,
  // status_reg, busy) reproduces the exact same edge-for-edge write
  // timing a real xpm_memory_spram would see from `mem[x] <= y`, since
  // its own write port is captured on the same clka edge these wires are
  // valid on.
  always_comb begin
    mem_we    = 1'b0;
    mem_waddr = '0;
    mem_wdata = 8'h00;
    if (RESETNeg) begin
      if (erase_active) begin
        mem_we    = 1'b1;
        mem_waddr = erase_addr;
        mem_wdata = 8'hff;
      end else if (command_complete && shifted_value != 8'h66 && shifted_value != 8'h99 &&
                   (shifted_value == 8'hc7 || shifted_value == 8'h60) &&
                   status_reg[1] && !busy) begin
        mem_we    = 1'b1;
        mem_waddr = '0;
        mem_wdata = 8'hff;
      end else if ((state == ST_ADDR) && ((bit_count + input_lanes) >= addr_bits) &&
                   status_reg[1] && !busy) begin
        if (cmd == CMD_SECTOR_ER) begin
          mem_we    = 1'b1;
          mem_waddr = (shifted_addr & 32'hfffff000);
          mem_wdata = 8'hff;
        end else if (cmd == CMD_BLOCK_ER) begin
          mem_we    = 1'b1;
          mem_waddr = (shifted_addr & 32'hffff0000);
          mem_wdata = 8'hff;
        end
      end else if (receive_complete && (cmd == CMD_PROGRAM || cmd == 8'h12) &&
                   status_reg[1] && !erase_active) begin
        mem_we    = 1'b1;
        mem_waddr = addr[MEM_ADDR_WIDTH-1:0];
        mem_wdata = shifted_value;
      end
    end
  end

  // Real Xilinx distributed-RAM (LUTRAM) read address -- combinational,
  // presented in the SAME cycle it is consumed, exactly matching the
  // arguments the original array-based `read_mem(a)` call sites used
  // (shifted_addr for the direct 0x03/0x13 read on ST_ADDR's final edge,
  // addr while parked in ST_DUMMY, addr+1 for ST_DATA_TX's own streaming
  // continuation). This is NOT a don't-care simplification: a real
  // hardened BRAM/URAM tile mandates >=1 cycle of registered read
  // latency (confirmed via Xilinx's own xpm_memory.sv DRC, and via a
  // first attempt at this file that added that latency back with a
  // dummy-cycle bubble for 0x03/0x13 -- see tb/tb_spi_flash_model_fpga_synt.sv
  // and this file's own revision history for the empirical failure that
  // caused this reversion). That approach broke real host compatibility:
  // axi_qspi_controller.sv's own XIP memory-mapped read path hardcodes
  // "Use CMD 03h ... ctrl_spidum = 0" (zero dummy cycles) as ITS real,
  // load-bearing read command -- not a corner case. A real NOR flash
  // satisfies zero-dummy 0x03 because its own internal array access is
  // asynchronous and fast enough within one (slow) SPI clock period, not
  // because of any dummy-cycle allowance; XPM's own distributed-RAM mode
  // (READ_LATENCY_A=0) matches that same asynchronous-read semantics
  // directly, whereas block/UltraRAM primitives cannot (Xilinx's own DRC
  // rejects READ_LATENCY_A=0 for those two specifically). So this file
  // uses distributed RAM, not block RAM, despite occupying real LUT
  // fabric (roughly 4k LUTs for 32KiB) rather than a BRAM/URAM tile --
  // trivial next to this design's ~1.4M LUT budget, and the only way to
  // keep a real Xilinx primitive AND the exact original protocol timing
  // the real host controller depends on.
  assign mem_read_addr =
      ((state == ST_ADDR) && ((bit_count + input_lanes) >= addr_bits) &&
       (cmd == 8'h03 || cmd == 8'h13)) ? shifted_addr[MEM_ADDR_WIDTH-1:0] :
      (state == ST_DATA_TX) ? (addr[MEM_ADDR_WIDTH-1:0] + 1'b1) :
      addr[MEM_ADDR_WIDTH-1:0];

  // Write always wins the shared address port -- harmless in practice
  // since mem_we and a "read actually being consumed this window" never
  // overlap (same mutual-exclusion argument as the write mux above), but
  // an explicit priority is more robust than relying on that alone.
  assign mem_addra = mem_we ? mem_waddr : mem_read_addr;

  // Real Xilinx distributed-RAM (LUTRAM) primitive -- same xpm_memory_spram
  // wrapper already proven in this codebase for BLOCK RAM
  // (deps/tech_cells_generic/src/fpga/tc_sram_xilinx.sv, confirmed
  // Mapped: Yes via an earlier mem.rpt) and the same real
  // MEMORY_INIT_FILE-driven preloading VROM's own FPGA stand-in uses
  // (deps/anc-adapter/fpga/src/ln04lpp_s00_mc_vromp_hd_lvt_1024x64m8b2c1_fpga.v's
  // xpm_memory_sprom instance) -- explicit primitive instantiation
  // instead of relying on a plain array being inferred, so preload and
  // real-primitive mapping are both guaranteed rather than left to a
  // synthesis tool's own inference heuristics (which, for this model,
  // silently optimized the plain-array version away entirely -- see this
  // file's revision history). MEMORY_PRIMITIVE is "distributed" (LUTRAM),
  // not "block" (BRAM/URAM) -- see mem_read_addr's own comment above for
  // why: zero-latency combinational reads are only legal for distributed
  // RAM, and this model's real host (axi_qspi_controller.sv's XIP path)
  // genuinely requires zero added read latency. WRITE_MODE_A must be
  // "read_first" here (xpm_memory_spram's own default, not "no_change"
  // used for BLOCK RAM elsewhere in this codebase) -- Xilinx's own DRC
  // rejects "no_change" for single-port distributed RAM. A single
  // read+write port suffices: writes (erase/program, from the
  // always_comb block above) and reads (this module's own SPI read FSM)
  // never happen on the same SCK edge, by construction (erase_active
  // forces ST_IGNORE for all non-RDSR commands, and the FSM only ever
  // occupies one state at a time).
  xpm_memory_spram #(
      .ADDR_WIDTH_A       (MEM_ADDR_WIDTH),
      .AUTO_SLEEP_TIME    (0),
      .BYTE_WRITE_WIDTH_A (8),
      .ECC_MODE           ("no_ecc"),
      .MEMORY_INIT_FILE   ((INIT_FILE != "") ? INIT_FILE : "none"),
      .MEMORY_INIT_PARAM  ("0"),
      .MEMORY_OPTIMIZATION("true"),
      .MEMORY_PRIMITIVE   ("distributed"),
      .MEMORY_SIZE        (MEM_DEPTH * 8),
      .MESSAGE_CONTROL    (0),
      .READ_DATA_WIDTH_A  (8),
      .READ_LATENCY_A     (0),
      .READ_RESET_VALUE_A ("0"),
      .USE_MEM_INIT       (1),
      .WAKEUP_TIME        ("disable_sleep"),
      .WRITE_DATA_WIDTH_A (8),
      .WRITE_MODE_A       ("read_first")
  ) i_xpm_memory_spram (
      .dbiterra      (/* not used */),
      .douta         (mem_douta),
      .sbiterra      (/* not used */),
      .addra         (mem_addra),
      .clka          (SCK),
      .dina          (mem_wdata),
      .ena           (1'b1),
      .injectdbiterra(1'b0),
      .injectsbiterra(1'b0),
      .regcea        (1'b1),
      .rsta          (~RESETNeg),
      .sleep         (1'b0),
      .wea           (mem_we)
  );

  // Transaction state.  CSNeg is the asynchronous transaction reset; it does
  // not reset persistent flash state such as WEL, QE, or 4-byte address mode.
  always @(posedge SCK or posedge CSNeg) begin
    if (CSNeg) begin
      state          <= ST_CMD;
      current_mode   <= MODE_SPI;
      cmd            <= 0;
      shift_reg      <= 0;
      addr           <= 0;
      bit_count      <= 0;
      addr_bits      <= 24;
      dummy_count    <= 0;
      tx_byte        <= 8'hff;
      id_index       <= 0;
      is_rdid        <= 1'b0;
      is_sfdp_read   <= 1'b0;
    end else begin
      case (state)
        ST_CMD: begin
          shift_reg <= shifted_value;
          if (command_complete) begin
            `ifdef DEBUG_QSPI_PRINT
            $display("[SPI_MODEL] command=%02h busy=%0b qpi=%0b", shifted_value, busy,
                     qpi_active);
            `endif
            cmd       <= shifted_value;
            bit_count <= 0;
            addr      <= 0;
            is_rdid   <= 1'b0;
            is_sfdp_read <= 1'b0;
            // Counter-based program/status busy time elapses while a command
            // is shifted in.  Only an in-progress serialized erase blocks the
            // command after its opcode has arrived.
            if (erase_active && shifted_value != CMD_RDSR) begin
              state <= ST_IGNORE;
            end else if (command_has_address(shifted_value)) begin
              state <= ST_ADDR;
              if (shifted_value == CMD_SFDP)
                addr_bits <= 24;
              else if (command_is_4byte(shifted_value) || addr_mode_4b)
                addr_bits <= 32;
              else
                addr_bits <= 24;
            end else begin
              case (shifted_value)
                CMD_RDID: begin
                  state    <= ST_DATA_TX;
                  tx_byte  <= 8'hef;
                  id_index <= 0;
                  is_rdid  <= 1'b1;
                end
                CMD_RDSR: begin
                  state   <= ST_DATA_TX;
                  tx_byte <= status_reg | {7'b0, busy};
                end
                CMD_WRSR: state <= ST_DATA_RX;
                default:  state <= ST_IGNORE;
              endcase
            end
          end else begin
            bit_count <= bit_count + input_lanes;
          end
        end

        ST_ADDR: begin
          addr <= shifted_addr;
          shift_reg <= shifted_value;
          if ((bit_count + input_lanes) >= addr_bits) begin
            `ifdef DEBUG_QSPI_PRINT
            $display("[SPI_MODEL] address=%08h command=%02h", shifted_addr, cmd);
            `endif
            bit_count <= 0;
            case (cmd)
              // Zero dummy cycles, matching real NOR flash's own 0x03/0x13
              // semantics exactly -- mem_read_addr presents shifted_addr
              // combinationally this same edge, and the distributed-RAM
              // primitive's own combinational (READ_LATENCY_A=0) output
              // makes mem_douta valid in time to consume below. See
              // mem_read_addr's own comment for why this model must not
              // add any bubble cycles here (real host controller
              // compatibility -- axi_qspi_controller.sv's XIP path issues
              // exactly this zero-dummy 0x03 sequence).
              8'h03, 8'h13: begin
                state <= ST_DATA_TX;
                tx_byte <= erase_shadows(shifted_addr) ? 8'hff : mem_douta;
              end
              8'h02, 8'h12: state <= ST_DATA_RX;
              8'h0b, 8'h0c: begin
                state <= ST_DUMMY;
                dummy_count <= 8;
                current_mode <= MODE_SPI;
              end
              8'h3b, 8'h3c, 8'hbd: begin
                state <= ST_DUMMY;
                dummy_count <= (cmd == 8'hbd) ? 6 : 8;
                current_mode <= MODE_DUAL;
              end
              8'h6b, 8'h6c, 8'hed: begin
                state <= ST_DUMMY;
                dummy_count <= (cmd == 8'hed) ? 6 : 8;
                current_mode <= MODE_QUAD;
              end
              8'h0d: begin
                state <= ST_DUMMY;
                dummy_count <= 6;
                current_mode <= MODE_SPI;
              end
              CMD_SFDP: begin
                state <= ST_DUMMY;
                dummy_count <= 8;
                current_mode <= MODE_SPI;
                is_sfdp_read <= 1'b1;
              end
              default: state <= ST_IGNORE;
            endcase
          end else begin
            bit_count <= bit_count + input_lanes;
          end
        end

        ST_DUMMY: begin
          if (dummy_count == 1) begin
            state <= ST_DATA_TX;
            bit_count <= 0;
            if (is_sfdp_read)
              tx_byte <= sfdp_byte(addr[7:0]);
            else
              tx_byte <= erase_shadows(addr) ? 8'hff : mem_douta;
          end else begin
            dummy_count <= dummy_count - 1'b1;
          end
        end

        ST_DATA_TX: begin
          if ((bit_count + output_lanes) >= 8) begin
            bit_count <= 0;
            addr <= addr + 1'b1;
            if (is_rdid) begin
              id_index <= id_index + 1'b1;
              case (id_index)
                2'd0: tx_byte <= 8'h40;
                2'd1: tx_byte <= 8'h18;
                default: tx_byte <= 8'hff;
              endcase
            end else if (is_sfdp_read) begin
              tx_byte <= sfdp_byte(addr[7:0] + 1'b1);
            end else if (cmd == CMD_RDSR) begin
              tx_byte <= status_reg | {7'b0, busy};
            end else begin
              tx_byte <= erase_shadows(addr + 1'b1) ? 8'hff : mem_douta;
            end
          end else begin
            bit_count <= bit_count + output_lanes;
          end
        end

        ST_DATA_RX: begin
          shift_reg <= shifted_value;
          if (receive_complete) begin
            bit_count <= 0;
            if (cmd == CMD_WRSR)
              state <= ST_IGNORE;
            else
              addr <= addr + 1'b1;
          end else begin
            bit_count <= bit_count + input_lanes;
          end
        end

        default: state <= ST_IGNORE;
      endcase
    end
  end

  // Combinational output mux.  Data changes immediately after the rising SCK
  // edge and is stable for the next rising edge, matching SPI mode 0 sampling.
  // No output-enable here: whether this model's value is actually used is
  // the consumer's decision (gated on the controller's own output-enable,
  // same oe-gated mux pattern as anc_padframe.sv's GPIO/boot_mode taps) --
  // this model just always presents what it *would* drive.
  reg io0_out, io1_out, io2_out, io3_out;
  always @* begin
    io0_out = 1'b0;
    io1_out = 1'b0;
    io2_out = 1'b0;
    io3_out = 1'b0;
    if (RESETNeg && !CSNeg && state == ST_DATA_TX) begin
      case (output_lanes)
        3'd4: begin
          io3_out = tx_byte[7-bit_count];
          io2_out = tx_byte[6-bit_count];
          io1_out = tx_byte[5-bit_count];
          io0_out = tx_byte[4-bit_count];
        end
        3'd2: begin
          io1_out = tx_byte[7-bit_count];
          io0_out = tx_byte[6-bit_count];
        end
        default: begin
          io1_out = tx_byte[7-bit_count];
        end
      endcase
    end
  end

  assign SI_o           = io0_out;
  assign SO_o           = io1_out;
  assign WPNeg_o        = io2_out;
  assign IO3_RESETNeg_o = io3_out;

endmodule
