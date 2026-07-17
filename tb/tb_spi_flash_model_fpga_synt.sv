`timescale 1ns / 1ps

// Standalone functional smoke test for spi_flash_model_fpga_synt.sv --
// specifically written to verify the xpm_memory_spram-based rewrite (real
// BRAM/URAM primitive + 1-cycle registered read latency retiming) behaves
// correctly, since no other testbench in this repo exercises this model's
// read path (tb_axi_qspi_controller.sv drives the OLD spi_flash_model.sv;
// the FPGA_EMU_BOOT_CONFIG's own FSBL never reads QSPI at runtime). Small
// MEM_ADDR_WIDTH (8 -> 256B) for fast simulation; the real build uses 15
// (32KiB) -- MEM_ADDR_WIDTH only changes storage depth, not any of the
// timing paths under test here.
module tb_spi_flash_model_fpga_synt;

  localparam integer MEM_ADDR_WIDTH = 8;
  localparam real SCK_HALF_PERIOD = 10.0;

  logic SCK, CSNeg, RESETNeg;
  logic SI_i, SO_i, WPNeg_i, IO3_RESETNeg_i;
  wire  SI_o, SO_o, WPNeg_o, IO3_RESETNeg_o;

  int errors = 0;
  int checks = 0;

  spi_flash_model_fpga_synt #(
      .MEM_ADDR_WIDTH(MEM_ADDR_WIDTH),
      .INIT_FILE(""),
      .PROGRAM_BUSY_CYCLES(4),
      .STATUS_BUSY_CYCLES(4)
  ) dut (
      .SCK           (SCK),
      .CSNeg         (CSNeg),
      .RESETNeg      (RESETNeg),
      .SI_i          (SI_i),
      .SI_o          (SI_o),
      .SO_i          (SO_i),
      .SO_o          (SO_o),
      .WPNeg_i       (WPNeg_i),
      .WPNeg_o       (WPNeg_o),
      .IO3_RESETNeg_i(IO3_RESETNeg_i),
      .IO3_RESETNeg_o(IO3_RESETNeg_o)
  );

  // ---------------------------------------------------------------------
  // SPI mode-0 bit-bang helpers. Data is set up, then SCK rises (DUT
  // samples on the rising edge); DUT's own output settles combinationally
  // right after the rising edge and holds until the next one, so the host
  // samples right after raising SCK too, matching the DUT header's own
  // "stable for the next rising edge" comment.
  // ---------------------------------------------------------------------
  task automatic sck_pulse();
    #(SCK_HALF_PERIOD) SCK = 1'b1;
    #(SCK_HALF_PERIOD) SCK = 1'b0;
  endtask

  task automatic spi_send_bit(input logic b);
    SI_i = b;
    #(SCK_HALF_PERIOD) SCK = 1'b1;
    #(SCK_HALF_PERIOD) SCK = 1'b0;
  endtask

  task automatic spi_send_byte(input logic [7:0] b);
    for (int i = 7; i >= 0; i--) spi_send_bit(b[i]);
  endtask

  task automatic spi_send_addr24(input logic [23:0] a);
    spi_send_byte(a[23:16]);
    spi_send_byte(a[15:8]);
    spi_send_byte(a[7:0]);
  endtask

  task automatic spi_recv_bit_single(output logic b);
    #(SCK_HALF_PERIOD) SCK = 1'b1;
    b = SO_o;
    #(SCK_HALF_PERIOD) SCK = 1'b0;
  endtask

  task automatic spi_recv_byte_single(output logic [7:0] b);
    logic bit_val;
    for (int i = 7; i >= 0; i--) begin
      spi_recv_bit_single(bit_val);
      b[i] = bit_val;
    end
  endtask

  task automatic spi_recv_byte_quad(output logic [7:0] b);
    logic [3:0] nib0, nib1;
    #(SCK_HALF_PERIOD) SCK = 1'b1;
    nib0 = {IO3_RESETNeg_o, WPNeg_o, SO_o, SI_o};
    #(SCK_HALF_PERIOD) SCK = 1'b0;
    #(SCK_HALF_PERIOD) SCK = 1'b1;
    nib1 = {IO3_RESETNeg_o, WPNeg_o, SO_o, SI_o};
    #(SCK_HALF_PERIOD) SCK = 1'b0;
    b = {nib0, nib1};
  endtask

  task automatic spi_begin();
    CSNeg = 1'b0;
  endtask

  task automatic spi_end();
    CSNeg = 1'b1;
    #(4 * SCK_HALF_PERIOD);
  endtask

  task automatic check_byte(input string label, input logic [7:0] got, input logic [7:0] exp);
    checks++;
    if (got !== exp) begin
      errors++;
      $display("[FAIL] %s: got=%02h expected=%02h", label, got, exp);
    end else begin
      $display("[PASS] %s: %02h", label, got);
    end
  endtask

  // WREN (0x06), then PROGRAM (0x02) one byte at a 24-bit address.
  task automatic program_byte(input logic [23:0] a, input logic [7:0] d);
    spi_begin();
    spi_send_byte(8'h06);
    spi_end();

    spi_begin();
    spi_send_byte(8'h02);
    spi_send_addr24(a);
    spi_send_byte(d);
    spi_end();

    wait_not_busy();
  endtask

  // WREN, then Sector Erase (0x20) at a 24-bit address.
  task automatic sector_erase(input logic [23:0] a);
    spi_begin();
    spi_send_byte(8'h06);
    spi_end();

    spi_begin();
    spi_send_byte(8'h20);
    spi_send_addr24(a);
    spi_end();

    wait_not_busy();
  endtask

  // Poll RDSR (0x05) until WIP (bit 0) clears. Each poll also advances SCK,
  // which is what actually serializes an in-progress erase one byte/edge.
  task automatic wait_not_busy();
    logic [7:0] sr;
    int guard;
    guard = 0;
    do begin
      spi_begin();
      spi_send_byte(8'h05);
      spi_recv_byte_single(sr);
      spi_end();
      guard++;
      if (guard > 2000) begin
        $display("[FAIL] wait_not_busy: never cleared WIP");
        errors++;
        break;
      end
    end while (sr[0]);
  endtask

  task automatic read_direct(input logic [23:0] a, output logic [7:0] d);
    spi_begin();
    spi_send_byte(8'h03);
    spi_send_addr24(a);
    spi_recv_byte_single(d);
    spi_end();
  endtask

  initial begin
    SCK            = 1'b0;
    CSNeg          = 1'b1;
    RESETNeg       = 1'b0;
    SI_i           = 1'b0;
    SO_i           = 1'b0;
    WPNeg_i        = 1'b1;
    IO3_RESETNeg_i = 1'b1;

    #(10 * SCK_HALF_PERIOD);
    RESETNeg = 1'b1;
    #(10 * SCK_HALF_PERIOD);

    // ---- Test 1: RDID ----------------------------------------------
    begin
      logic [7:0] id0, id1, id2;
      spi_begin();
      spi_send_byte(8'h9f);
      spi_recv_byte_single(id0);
      spi_recv_byte_single(id1);
      spi_recv_byte_single(id2);
      spi_end();
      check_byte("RDID byte0", id0, 8'hef);
      check_byte("RDID byte1", id1, 8'h40);
      check_byte("RDID byte2", id2, 8'h18);
    end

    // ---- Test 2: program + direct read (0x03), single byte ---------
    // Exercises the dummy_count=2 retiming added for 0x03/0x13's lack of
    // a natural dummy phase to absorb the real BRAM's 1-cycle latency.
    begin
      logic [7:0] rd;
      program_byte(24'h000010, 8'hA5);
      read_direct(24'h000010, rd);
      check_byte("direct read after program (0x03)", rd, 8'hA5);
    end

    // ---- Test 3: multi-byte streaming direct read -------------------
    // Exercises the addr+1 prefetch path inside ST_DATA_TX.
    begin
      logic [7:0] b0, b1, b2, b3;
      program_byte(24'h000020, 8'h11);
      program_byte(24'h000021, 8'h22);
      program_byte(24'h000022, 8'h33);
      program_byte(24'h000023, 8'h44);

      spi_begin();
      spi_send_byte(8'h03);
      spi_send_addr24(24'h000020);
      spi_recv_byte_single(b0);
      spi_recv_byte_single(b1);
      spi_recv_byte_single(b2);
      spi_recv_byte_single(b3);
      spi_end();
      check_byte("stream byte0", b0, 8'h11);
      check_byte("stream byte1", b1, 8'h22);
      check_byte("stream byte2", b2, 8'h33);
      check_byte("stream byte3", b3, 8'h44);
    end

    // ---- Test 4: fast read (0x0b, 8 dummy cycles) --------------------
    begin
      logic [7:0] b0, b1;
      spi_begin();
      spi_send_byte(8'h0b);
      spi_send_addr24(24'h000020);
      for (int i = 0; i < 8; i++) sck_pulse();
      spi_recv_byte_single(b0);
      spi_recv_byte_single(b1);
      spi_end();
      check_byte("fast read (0x0b) byte0", b0, 8'h11);
      check_byte("fast read (0x0b) byte1", b1, 8'h22);
    end

    // ---- Test 5: quad output fast read (0x6b, 8 dummy cycles) --------
    begin
      logic [7:0] b0, b1;
      spi_begin();
      spi_send_byte(8'h6b);
      spi_send_addr24(24'h000020);
      for (int i = 0; i < 8; i++) sck_pulse();
      spi_recv_byte_quad(b0);
      spi_recv_byte_quad(b1);
      spi_end();
      check_byte("quad fast read (0x6b) byte0", b0, 8'h11);
      check_byte("quad fast read (0x6b) byte1", b1, 8'h22);
    end

    // ---- Test 6: sector erase, then verify erased region reads 0xff -
    begin
      logic [7:0] rd;
      sector_erase(24'h000020);
      read_direct(24'h000020, rd);
      check_byte("read after sector erase", rd, 8'hff);
    end

    $display("==============================================");
    if (errors == 0)
      $display("[SUMMARY] ALL %0d CHECKS PASSED", checks);
    else
      $display("[SUMMARY] %0d/%0d CHECKS FAILED", errors, checks);
    $display("==============================================");
    $finish;
  end

endmodule
