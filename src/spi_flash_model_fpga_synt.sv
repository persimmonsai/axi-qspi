`timescale 1ns / 1ps

// Synthesizable SPI/QSPI flash model intended for FPGA-based emulation.
//
// The model deliberately uses only a fixed-size memory, one SCK edge, and
// counters.  Flash addresses alias into MEM_ADDR_WIDTH bits.  Long erase
// operations are performed one byte per SCK edge; software polling RDSR
// supplies the clocks needed to complete them.
module spi_flash_model_fpga_synt #(
    parameter integer MEM_ADDR_WIDTH = 20,
    parameter         INIT_FILE      = "",
    parameter integer PROGRAM_BUSY_CYCLES = 16,
    parameter integer STATUS_BUSY_CYCLES  = 8
) (
    inout  wire SI,           // IO0
    inout  wire SO,           // IO1
    input  wire SCK,
    input  wire CSNeg,
    inout  wire WPNeg,        // IO2
    input  wire RESETNeg,
    inout  wire IO3_RESETNeg  // IO3
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

  logic [7:0] mem [0:MEM_DEPTH-1];

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

  wire io0_in = SI;
  wire io1_in = SO;
  wire io2_in = WPNeg;
  wire io3_in = IO3_RESETNeg;

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

  function automatic logic [7:0] read_mem(input logic [31:0] a);
    logic [MEM_ADDR_WIDTH:0] read_index;
    begin
      read_index = {1'b0, a[MEM_ADDR_WIDTH-1:0]};
      // An erase is logically complete as soon as it is accepted.  The RAM
      // locations are then physically cleared at one byte per later SCK.
      if (erase_active &&
          read_index >= {1'b0, erase_addr} &&
          read_index < ({1'b0, erase_addr} + erase_count))
        read_mem = 8'hff;
      else
        read_mem = mem[a[MEM_ADDR_WIDTH-1:0]];
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

  integer init_i;
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
    if (INIT_FILE != "") begin
      $readmemh(INIT_FILE, mem);
    end else begin
      for (init_i = 0; init_i < MEM_DEPTH; init_i = init_i + 1)
        mem[init_i] = 8'hff;
    end
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
        mem[erase_addr] <= 8'hff;
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
                mem[0]       <= 8'hff;
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
          mem[(shifted_addr & 32'hfffff000)] <= 8'hff;
          erase_active <= (SECTOR_ERASE_COUNT > 1);
          erase_addr <= (shifted_addr & 32'hfffff000) + 1'b1;
          erase_count <= SECTOR_ERASE_COUNT - 1'b1;
          status_reg[1] <= 1'b0;
        end else if (cmd == CMD_BLOCK_ER) begin
          mem[(shifted_addr & 32'hffff0000)] <= 8'hff;
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
          mem[addr[MEM_ADDR_WIDTH-1:0]] <= shifted_value;
          busy_count <= PROGRAM_BUSY_CYCLES;
        end
      end
    end
  end

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
            $display("[SPI_MODEL] address=%08h command=%02h data=%02h", shifted_addr,
                     cmd, read_mem(shifted_addr));
            `endif
            bit_count <= 0;
            case (cmd)
              8'h03, 8'h13: begin
                state <= ST_DATA_TX;
                tx_byte <= read_mem(shifted_addr);
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
              tx_byte <= read_mem(addr);
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
              tx_byte <= read_mem(addr + 1'b1);
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
  reg io0_oe, io1_oe, io2_oe, io3_oe;
  reg io0_out, io1_out, io2_out, io3_out;
  always @* begin
    io0_oe  = 1'b0;
    io1_oe  = 1'b0;
    io2_oe  = 1'b0;
    io3_oe  = 1'b0;
    io0_out = 1'b0;
    io1_out = 1'b0;
    io2_out = 1'b0;
    io3_out = 1'b0;
    if (RESETNeg && !CSNeg && state == ST_DATA_TX) begin
      case (output_lanes)
        3'd4: begin
          io0_oe  = 1'b1;
          io1_oe  = 1'b1;
          io2_oe  = 1'b1;
          io3_oe  = 1'b1;
          io3_out = tx_byte[7-bit_count];
          io2_out = tx_byte[6-bit_count];
          io1_out = tx_byte[5-bit_count];
          io0_out = tx_byte[4-bit_count];
        end
        3'd2: begin
          io0_oe  = 1'b1;
          io1_oe  = 1'b1;
          io1_out = tx_byte[7-bit_count];
          io0_out = tx_byte[6-bit_count];
        end
        default: begin
          io1_oe  = 1'b1;
          io1_out = tx_byte[7-bit_count];
        end
      endcase
    end
  end

  assign SI           = io0_oe ? io0_out : 1'bz;
  assign SO           = io1_oe ? io1_out : 1'bz;
  assign WPNeg        = io2_oe ? io2_out : 1'bz;
  assign IO3_RESETNeg = io3_oe ? io3_out : 1'bz;

  // Simulation-only backdoor helpers retained for the existing testbench.
  // synthesis translate_off
  task write_mem(input integer a, input logic [7:0] d);
    if (a >= 0 && a < MEM_DEPTH)
      mem[a] = d;
  endtask

  task reset_internals;
  endtask

  task save_memory(input string filename);
    $writememh(filename, mem);
  endtask

  task load_memory(input string filename);
    $readmemh(filename, mem);
  endtask
  // synthesis translate_on

endmodule
