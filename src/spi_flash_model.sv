`timescale 1ns / 1ps

module spi_flash_model (
    inout wire SI,           // IO0
    inout wire SO,           // IO1
    input wire SCK,
    input wire CSNeg,
    inout wire WPNeg,        // IO2
    input wire RESETNeg,
    inout wire IO3_RESETNeg  // IO3
);

  // =========================================================================
  // Parameters & Memory
  // =========================================================================
  logic [7:0] mem                                               [int unsigned];

  // Status Register 1
  logic [7:0] status_reg = 8'h40;  // Default QE=1

  // Internal State
  logic       addr_mode_4b = 0;
  logic       qpi_active = 0;
  logic       is_ddr = 0;  // Current command is DDR
  logic       is_sfdp_read = 0;  // Current command is Read SFDP
  logic       reset_enable = 0;
  time        busy_until = 0;

  // SFDP Memory Size
  localparam SFDP_SIZE = 256;
  logic [7:0] sfdp_rom[0:SFDP_SIZE-1];

  initial begin
    // Initialize SFDP ROM with 0xFF
    for (int i = 0; i < SFDP_SIZE; i++) sfdp_rom[i] = 8'hFF;

    // --- SFDP Header (0x00 - 0x07) ---
    // ... (Snip SFDP - Unchanged)
  end

  // =========================================================================
  // Internal Signals
  // =========================================================================
  typedef enum logic [2:0] {
    ST_IDLE,
    ST_CMD,
    ST_ADDR,
    ST_DUMMY,
    ST_DATA_TX,
    ST_DATA_RX
  } flash_state_t;
  flash_state_t state = ST_IDLE;

  typedef enum logic [1:0] {
    MODE_SPI,
    MODE_DUAL,
    MODE_QUAD
  } spi_mode_t;
  spi_mode_t current_mode = MODE_SPI;

  int unsigned bit_cnt;
  logic [31:0] addr;
  logic [31:0] shift_reg;
  logic [7:0] cmd;
  int unsigned dummy_cycles;
  logic [7:0] tx_byte;

  logic io0_oe, io1_oe, io2_oe, io3_oe;
  logic io0_out, io1_out, io2_out, io3_out;
  wire io0_in, io1_in, io2_in, io3_in;

  assign io0_in       = SI;
  assign io1_in       = SO;
  assign io2_in       = WPNeg;
  assign io3_in       = IO3_RESETNeg;

  assign SI           = io0_oe ? io0_out : 1'bz;
  assign SO           = io1_oe ? io1_out : 1'bz;
  assign WPNeg        = io2_oe ? io2_out : 1'bz;
  assign IO3_RESETNeg = io3_oe ? io3_out : 1'bz;

  // =========================================================================
  // Reset Logic
  // =========================================================================


  function logic [7:0] get_mem_byte(input logic [31:0] a);
    if (mem.exists(a)) begin
      $display("[SPI_MODEL] Get Byte: Addr=%h Data=%h", a, mem[a]);
      return mem[a];
    end else begin
      $display("[SPI_MODEL] Get Byte: Addr=%h Data=FF (Miss)", a);
      return 8'hFF;
    end
  endfunction

  function logic is_busy();
    return ($time < busy_until);
  endfunction

  // =========================================================================
  // Main FSM
  // =========================================================================
  // Trigger on both edges for DDR support
  always @(posedge SCK or negedge SCK or posedge CSNeg or negedge RESETNeg) begin
    if (!RESETNeg) begin
      state <= ST_IDLE;
      $display("[SPI_MODEL] RESETNeg detected. Resetting internals.");
      io0_oe       <= 0;
      io1_oe       <= 0;
      io2_oe       <= 0;
      io3_oe       <= 0;
      current_mode <= MODE_SPI;
      bit_cnt      <= 0;
      addr         <= 0;
      shift_reg    <= 0;
      status_reg   <= 8'h40;
      dummy_cycles <= 0;
      tx_byte      <= 0;
      addr_mode_4b <= 0;
      qpi_active   <= 0;
      is_ddr       <= 0;
      is_sfdp_read <= 0;
      reset_enable <= 0;
      busy_until   <= 0;
    end else if (CSNeg) begin
      if (state == ST_DATA_RX && cmd != 8'h01) begin  // If finishing Page Program (and not WRSR)
        // Assuming we were programming
        busy_until <= $time + 1000;  // 1us Busy after Program
      end

      state <= ST_IDLE;
      io0_oe <= 0;
      io1_oe <= 0;
      io2_oe <= 0;
      io3_oe <= 0;
      current_mode <= MODE_SPI;
      is_ddr <= 0;
      is_sfdp_read <= 0;
      bit_cnt <= 0;
    end else begin
      // Determine if we should process this edge
      // SDR: Only Posedge SCK
      // DDR: Posedge and Negedge SCK
      logic process_edge;
      if (is_ddr) process_edge = 1;
      else process_edge = SCK;  // True if Posedge (1), False if Negedge (0)

      if (process_edge) begin
        case (state)
          ST_IDLE: begin
            if (is_busy() && !qpi_active) begin
              // If BUSY, ignore new commands? 
              // Real flash ignores everything except RDSR (05h) and Suspend (75h).
              // We will check cmd in ST_CMD to filter.
            end

            state <= ST_CMD;
            bit_cnt <= 0;
            shift_reg <= 0;
            is_ddr <= 0;
            is_sfdp_read <= 0;

            if (qpi_active) begin
              current_mode <= MODE_QUAD;
              shift_reg <= {io3_in, io2_in, io1_in, io0_in, 4'b0};
              bit_cnt <= 4;
            end else begin
              current_mode <= MODE_SPI;
              shift_reg <= {shift_reg[6:0], io0_in};
              bit_cnt <= 1;
            end
          end

          ST_CMD: begin
            logic [7:0] next_shift;
            int inc;

            if (qpi_active) begin
              next_shift = {shift_reg[7:4], io3_in, io2_in, io1_in, io0_in};
              inc = 4;
            end else begin
              next_shift = {shift_reg[6:0], io0_in};
              inc = 1;
            end

            shift_reg <= next_shift;
            bit_cnt   <= bit_cnt + inc;

            if (bit_cnt + inc >= 8) begin  // Changed > 8 to >= 8 for robustness
              cmd <= next_shift;
              bit_cnt <= 0;
              addr <= 0;

              // Check for DTR commands immediately
              if (next_shift == 8'h0D || next_shift == 8'hBD || next_shift == 8'hED) is_ddr <= 1;

              // Reset Enable Logic
              if (next_shift == 8'h66) begin
                reset_enable <= 1;
                state <= ST_IDLE;
                $display("[SPI_MODEL] RSTEN (66h) Executed. Reset Enable Set.");
              end else if (next_shift == 8'h99) begin
                if (reset_enable) begin
                  $display("[SPI_MODEL] RST (99h) Executed. Resetting Model.");
                  io0_oe       <= 0;
                  io1_oe       <= 0;
                  io2_oe       <= 0;
                  io3_oe       <= 0;
                  current_mode <= MODE_SPI;
                  bit_cnt      <= 0;
                  addr         <= 0;
                  shift_reg    <= 0;
                  status_reg   <= 8'h40;
                  dummy_cycles <= 0;
                  tx_byte      <= 0;
                  addr_mode_4b <= 0;
                  qpi_active   <= 0;
                  is_ddr       <= 0;
                  is_sfdp_read <= 0;
                  reset_enable <= 0;
                  busy_until   <= 0;
                  state        <= ST_IDLE;
                end else begin
                  $display("[SPI_MODEL] RST (99h) Ignored (RSTEN not set).");
                  state <= ST_IDLE;
                end
              end else begin
                // Any other command clears reset_enable (Standard behavior varies, but safe assumption)
                reset_enable <= 0;

                // BUSY Check
                if (is_busy() && next_shift != 8'h05) begin
                  $display("[SPI_MODEL] Device BUSY. Command %h ignored.", next_shift);
                  state <= ST_IDLE;
                end else begin
                  case (next_shift)
                    // Read / Prog / Erase
                    8'h03, 8'h0B, 8'h3B, 8'h6B, 8'h02, 8'h20, 8'hD8, 8'h0D, 8'hBD, 8'hED,  // DTR Reads
                    8'h13, 8'h0C, 8'h12, 8'h3C, 8'h6C: begin
                      state <= ST_ADDR;
                    end

                    8'h9F: begin  // RDID
                      state   <= ST_DATA_TX;
                      tx_byte <= 8'h01;
                      bit_cnt <= 0;
                    end
                    8'h05: begin  // RDSR
                      state   <= ST_DATA_TX;
                      tx_byte <= status_reg | (is_busy() ? 8'h01 : 8'h00);  // Return BUSY if set
                      bit_cnt <= 0;
                    end
                    8'h01: begin  // WRSR
                      state <= ST_DATA_RX;  // Write Status Register
                    end
                    8'h06: begin  // WREN
                      status_reg[1] <= 1;
                      state <= ST_IDLE;
                    end

                    8'hB7: begin
                      addr_mode_4b <= 1;
                      $display("[SPI_MODEL] EN4BA Executed");
                      state <= ST_IDLE;
                    end
                    8'hE9: begin
                      addr_mode_4b <= 0;
                      state <= ST_IDLE;
                      $display("[SPI_MODEL] EX4BA Executed. Returning to 3-byte mode.");
                    end

                    8'h38: begin
                      qpi_active <= 1;
                      state <= ST_IDLE;
                      $display("[SPI_MODEL] EQPI Executed");
                    end  // EQPI
                    8'hFF: begin
                      qpi_active <= 0;
                      state <= ST_IDLE;
                    end  // RSTQPI (Reset QPI)

                    8'hC7, 8'h60: begin  // CE
                      if (status_reg[1]) begin
                        mem.delete();
                        busy_until <= $time + 20000;  // 20us Busy
                      end
                      state <= ST_IDLE;
                    end
                    8'h5A: begin  // Read SFDP
                      state <= ST_ADDR;
                      is_sfdp_read <= 1;
                    end
                    default: state <= ST_IDLE;
                  endcase
                end
              end
            end else begin
              bit_cnt <= bit_cnt + inc;
            end
          end

          ST_ADDR: begin
            logic [7:0] next_shift;
            int inc;
            logic [31:0] full_cnt;
            logic [31:0] next_addr;

            full_cnt = (addr_mode_4b && !is_sfdp_read) ? 32 : 24;

            if (qpi_active || current_mode == MODE_QUAD) begin
              if (qpi_active) begin
                next_shift = {shift_reg[3:0], io3_in, io2_in, io1_in, io0_in};  // Shift 4 in 
                inc = 4;
              end else begin
                next_shift = {shift_reg[6:0], io0_in};
                inc = 1;
              end
            end else begin
              next_shift = {shift_reg[6:0], io0_in};
              inc = 1;
            end

            shift_reg <= next_shift;
            bit_cnt   <= bit_cnt + inc;

            if ((bit_cnt + inc) % 8 == 0) begin  // Byte boundary
              // Accumulate address by shifting left and appending new byte
              next_addr = {addr[23:0], next_shift};
              addr <= next_addr;
              // $display("[SPI_MODEL] Accumulating Addr: NewAddr=%h, Byte=%h, bit_cnt=%0d, full_cnt=%0d, 4b=%0d", next_addr, next_shift, (bit_cnt+inc), full_cnt, addr_mode_4b);

              if (bit_cnt + inc >= full_cnt) begin
                // Address complete
                bit_cnt <= 0;

                // Handle Mode & Dummy
                case (cmd)
                  8'h03, 8'h13: begin
                    automatic logic [7:0] val = get_mem_byte(next_addr);
                    state   <= ST_DATA_TX;
                    tx_byte <= val;
                    // Immediate Drive
                    io1_oe  <= 1;
                    io1_out <= val[7];
                    bit_cnt <= 0;
                  end

                  8'h02, 8'h12: begin
                    state <= ST_DATA_RX;
                  end

                  8'h0B, 8'h0C: begin
                    state <= ST_DUMMY;
                    dummy_cycles <= 8;
                  end

                  8'h3B, 8'h3C: begin
                    state <= ST_DUMMY;
                    dummy_cycles <= 8;
                    current_mode <= MODE_DUAL;
                  end  // Dual Output
                  8'h6B, 8'h6C: begin
                    state <= ST_DUMMY;
                    dummy_cycles <= 8;
                    current_mode <= MODE_QUAD;
                  end  // Quad Output

                  8'h0D: begin
                    state <= ST_DUMMY;
                    dummy_cycles <= 6;
                    current_mode <= MODE_SPI;
                    is_ddr <= 1;
                  end  // Fast Read DTR
                  8'hBD: begin
                    state <= ST_DUMMY;
                    dummy_cycles <= 6;
                    current_mode <= MODE_DUAL;
                    is_ddr <= 1;
                  end
                  8'hED: begin
                    state <= ST_DUMMY;
                    dummy_cycles <= 6;
                    current_mode <= MODE_QUAD;
                    is_ddr <= 1;
                  end

                  8'h5A: begin
                    state <= ST_DUMMY;
                    dummy_cycles <= 8;
                    current_mode <= MODE_SPI;
                  end

                  8'h20: begin
                    if (status_reg[1]) begin
                      for (int i = 0; i < 4096; i++)
                      if (mem.exists(next_addr + i)) mem.delete(next_addr + i);
                      busy_until <= $time + 5000;  // 5us Busy
                    end
                    state <= ST_IDLE;
                  end
                  8'hD8: begin
                    if (status_reg[1]) begin
                      for (int i = 0; i < 65536; i++)
                      if (mem.exists(next_addr + i)) mem.delete(next_addr + i);
                      busy_until <= $time + 10000;  // 10us Busy
                    end
                    state <= ST_IDLE;
                  end

                  default: state <= ST_IDLE;
                endcase
              end
            end
          end

          ST_DUMMY: begin
            dummy_cycles <= dummy_cycles - 1;
            if (dummy_cycles == 1) begin
              state <= ST_DATA_TX;
              if (is_sfdp_read) begin
                if (addr < SFDP_SIZE) tx_byte <= sfdp_rom[addr];
                else tx_byte <= 8'hFF;
              end else begin
                tx_byte <= get_mem_byte(addr);
              end
              bit_cnt <= 0;
            end
          end

          ST_DATA_TX: begin
            // Advance State Logic (Address increment, Byte fetch)
            // Output driving is separate.
            int bits_per_edge;  // Per processed edge
            if (current_mode == MODE_QUAD || qpi_active) bits_per_edge = 4;
            else if (current_mode == MODE_DUAL) bits_per_edge = 2;
            else bits_per_edge = 1;

            bit_cnt <= bit_cnt + bits_per_edge;

            if (bit_cnt + bits_per_edge >= 8) begin
              bit_cnt <= 0;
              // Byte Done
              addr <= addr + 1;
              if (is_sfdp_read) begin
                if ((addr + 1) < SFDP_SIZE) tx_byte <= sfdp_rom[addr+1];
                else tx_byte <= 8'hFF;
              end else begin
                tx_byte <= get_mem_byte(addr + 1);
              end
            end
          end

          ST_DATA_RX: begin
            // Simplified RX
            automatic logic [7:0] next_shift = {shift_reg[6:0], io0_in};  // Assuming SPI for Prog
            shift_reg <= next_shift;
            bit_cnt   <= bit_cnt + 1;
            if (bit_cnt == 7) begin
              if (cmd == 8'h01) begin  // WRSR
                if (status_reg[1]) begin  // WREN must be set
                  status_reg <= (next_shift & 8'hFC) | (status_reg & 8'h02); // Keep WEL, clear BUSY (actually BUSY is dynamic)
                  status_reg[1] <= 0;  // Clear WEL
                  $display("[SPI_MODEL] WRSR Executed. New Status: %h", next_shift);
                  busy_until <= $time + 1000;  // 1us Busy
                end
                state <= ST_IDLE;  // Assume 1 byte write for now
              end else if (status_reg[1]) begin  // Page Program
                mem[addr] = next_shift;
                $display("[SPI_MODEL] Writing Mem: Addr=%h Data=%h", addr, next_shift);
                addr <= addr + 1;
              end
              bit_cnt <= 0;
            end
          end
        endcase
      end

      // Output Drive Logic
      // Driven on Negedge for SDR.
      if (state == ST_DATA_TX) begin
        if (is_ddr || !SCK) begin
          case (current_mode)
            MODE_SPI: begin
              if (!qpi_active) begin
                io1_oe  <= 1;  // SO
                io1_out <= tx_byte[7-bit_cnt];
              end else begin
                // QPI Mode Output (Quad)
                io0_oe  <= 1;
                io1_oe  <= 1;
                io2_oe  <= 1;
                io3_oe  <= 1;
                io3_out <= tx_byte[7-bit_cnt];
                io2_out <= tx_byte[7-bit_cnt-1];  // etc?
                // QPI logic matches Quad
                io3_out <= tx_byte[7-bit_cnt];  // 7, 3
                io2_out <= tx_byte[6-bit_cnt];  // 6, 2
                io1_out <= tx_byte[5-bit_cnt];  // 5, 1
                io0_out <= tx_byte[4-bit_cnt];  // 4, 0
              end
            end

            MODE_DUAL: begin
              io0_oe  <= 1;
              io1_oe  <= 1;
              io1_out <= tx_byte[7-bit_cnt];  // 7, 5, 3, 1
              io0_out <= tx_byte[6-bit_cnt];  // 6, 4, 2, 0
            end

            MODE_QUAD: begin
              io0_oe  <= 1;
              io1_oe  <= 1;
              io2_oe  <= 1;
              io3_oe  <= 1;
              io3_out <= tx_byte[7-bit_cnt];  // 7, 3
              io2_out <= tx_byte[6-bit_cnt];
              io1_out <= tx_byte[5-bit_cnt];
              io0_out <= tx_byte[4-bit_cnt];
            end
          endcase
        end
      end

    end
  end

  // =========================================================================
  // Output Logic
  // =========================================================================

  // =========================================================================
  // Backdoor Access Tasks
  // =========================================================================
  task write_mem(input int a, input logic [7:0] d);
    mem[a] = d;
    $display("[SPI_MODEL] Backdoor Write: Addr=%h Data=%h", a, d);
  endtask

  task reset_internals();
    // Deprecated: Internal resets are now handled in the main always block
  endtask

  // =========================================================================
  // Persistence Utilities
  // =========================================================================

  task save_memory(input string filename);
    int fd;
    fd = $fopen(filename, "w");
    if (fd) begin
      foreach (mem[a]) begin  // Changed addr to a to avoid masking
        $fdisplay(fd, "@%h %h", a, mem[a]);
      end
      $fclose(fd);
      $display("[SPI_MODEL] Memory saved to %s", filename);
    end else begin
      $error("[SPI_MODEL] Failed to open %s for writing", filename);
    end
  endtask

  task load_memory(input string filename);
    int fd;
    logic [31:0] a;  // Changed local addr to a
    logic [7:0] data;
    int code;
    string line;

    fd = $fopen(filename, "r");
    if (fd) begin
      while (!$feof(
          fd
      )) begin
        if ($fgets(line, fd)) begin
          code = $sscanf(line, "@%h %h", a, data);
          if (code == 2) begin
            mem[a] = data;
          end
        end
      end
      $fclose(fd);
      $display("[SPI_MODEL] Memory loaded from %s", filename);
    end else begin
      $display("[SPI_MODEL] Warning: Could not open %s for reading. Starting empty/default.",
               filename);
    end
  endtask

  initial begin
    // Initial block no longer calls reset_internals because reset is handled by signal
    // If you need power-on reset simulation without asserting RESETNeg, you might need to
    // manually set initial values here.
    io0_oe       = 0;
    io1_oe       = 0;
    io2_oe       = 0;
    io3_oe       = 0;
    current_mode = MODE_SPI;
    bit_cnt      = 0;
    addr         = 0;
    shift_reg    = 0;
    status_reg   = 8'h40;
    dummy_cycles = 0;
    tx_byte      = 0;
    addr_mode_4b = 0;
    qpi_active   = 0;
    is_ddr       = 0;
    is_sfdp_read = 0;
    reset_enable = 0;
    busy_until   = 0;
  end

endmodule
