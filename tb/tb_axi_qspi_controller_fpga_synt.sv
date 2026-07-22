`timescale 1ns / 1ps

// Integration testbench: axi_qspi_controller.sv (the real, shared host
// controller, with this session's rx_last_word_o / addr_mode fixes) driven
// against spi_flash_model_fpga_synt.sv (the REAL model used by the actual
// FPGA_EMU_BOOT_CONFIG build, not spi_flash_model.sv). This gap existed
// because every other testbench in this repo exercises the controller
// fixes against the OLD, full-featured sim model, and the new FPGA model
// in isolation against a hand-rolled bit-bang harness -- the two had never
// been run together end-to-end. No `inout`/tri-state wiring is needed here
// (unlike tb_axi_qspi_controller.sv's spi_io bus): the controller's own
// spi_sdo*/spi_oe*/spi_sdi* ports are already split, so the flash model's
// own split _i/_o ports connect via a plain oe-gated mux, matching the
// real fpga_syn/rtl/haps200_top_fpga_wrapper.sv wiring pattern.
//
// Content is preloaded via INIT_FILE (matching the plain, one-hex-byte-
// per-line format xpm_memory itself expects, established when this model
// was rewritten around xpm_memory_spram) rather than live WREN+PP, since
// the goal here is verifying the controller's READ path (0x03/0x0B/0x6B/
// burst) against the real model -- the WRITE path is already independently
// verified by tb_spi_flash_model_fpga_synt.sv's own direct bit-bang tests.
module tb_axi_qspi_controller_fpga_synt;

  localparam int unsigned AXI_ADDR_WIDTH = 32;
  localparam AXI_DATA_WIDTH = 32;
  localparam AXI_ID_WIDTH = 4;
  localparam AXI_USER_WIDTH = 4;

  logic clk, rstn, fetch_en;

  logic s_axi_awvalid;
  logic [AXI_ID_WIDTH-1:0] s_axi_awid;
  logic [7:0] s_axi_awlen;
  logic [AXI_ADDR_WIDTH-1:0] s_axi_awaddr;
  logic [AXI_USER_WIDTH-1:0] s_axi_awuser;
  logic s_axi_awready;

  logic s_axi_wvalid;
  logic [AXI_DATA_WIDTH-1:0] s_axi_wdata;
  logic [AXI_DATA_WIDTH/8-1:0] s_axi_wstrb;
  logic s_axi_wlast;
  logic [AXI_USER_WIDTH-1:0] s_axi_wuser;
  logic s_axi_wready;

  logic s_axi_bvalid;
  logic [AXI_ID_WIDTH-1:0] s_axi_bid;
  logic [1:0] s_axi_bresp;
  logic [AXI_USER_WIDTH-1:0] s_axi_buser;
  logic s_axi_bready;

  logic s_axi_arvalid;
  logic [AXI_ID_WIDTH-1:0] s_axi_arid;
  logic [7:0] s_axi_arlen;
  logic [AXI_ADDR_WIDTH-1:0] s_axi_araddr;
  logic [AXI_USER_WIDTH-1:0] s_axi_aruser;
  logic s_axi_arready;

  logic s_axi_rvalid;
  logic [AXI_ID_WIDTH-1:0] s_axi_rid;
  logic [AXI_DATA_WIDTH-1:0] s_axi_rdata;
  logic [1:0] s_axi_rresp;
  logic s_axi_rlast;
  logic [AXI_USER_WIDTH-1:0] s_axi_ruser;
  logic s_axi_rready;

  logic [1:0] events_o;

  wire spi_clk;
  wire [3:0] spi_csn;
  wire [1:0] spi_mode;
  wire spi_sdo0, spi_sdo1, spi_sdo2, spi_sdo3;
  wire spi_oe0, spi_oe1, spi_oe2, spi_oe3;
  wire spi_sdi0, spi_sdi1, spi_sdi2, spi_sdi3;
  wire flash_si_o, flash_so_o, flash_wpneg_o, flash_io3_o;

  // Oe-gated mux (no tri-state): if the controller itself is driving a
  // line this cycle, it reads back its own driven value; otherwise it
  // reads what the flash model is driving. Same pattern
  // haps200_top_fpga_wrapper.sv uses for the real FPGA wiring.
  assign spi_sdi0 = spi_oe0 ? spi_sdo0 : flash_si_o;
  assign spi_sdi1 = spi_oe1 ? spi_sdo1 : flash_so_o;
  assign spi_sdi2 = spi_oe2 ? spi_sdo2 : flash_wpneg_o;
  assign spi_sdi3 = spi_oe3 ? spi_sdo3 : flash_io3_o;

  axi_qspi_controller #(
      .AXI4_ADDRESS_WIDTH(AXI_ADDR_WIDTH),
      .AXI4_RDATA_WIDTH  (AXI_DATA_WIDTH),
      .AXI4_WDATA_WIDTH  (AXI_DATA_WIDTH),
      .AXI4_ID_WIDTH     (AXI_ID_WIDTH),
      .AXI4_USER_WIDTH   (AXI_USER_WIDTH)
  ) dut (
      .s_axi_aclk(clk),
      .s_axi_aresetn(rstn),
      .s_axi_awvalid(s_axi_awvalid),
      .s_axi_awid(s_axi_awid),
      .s_axi_awlen(s_axi_awlen),
      .s_axi_awaddr(s_axi_awaddr),
      .s_axi_awuser(s_axi_awuser),
      .s_axi_awready(s_axi_awready),
      .s_axi_wvalid(s_axi_wvalid),
      .s_axi_wdata(s_axi_wdata),
      .s_axi_wstrb(s_axi_wstrb),
      .s_axi_wlast(s_axi_wlast),
      .s_axi_wuser(s_axi_wuser),
      .s_axi_wready(s_axi_wready),
      .s_axi_bvalid(s_axi_bvalid),
      .s_axi_bid(s_axi_bid),
      .s_axi_bresp(s_axi_bresp),
      .s_axi_buser(s_axi_buser),
      .s_axi_bready(s_axi_bready),
      .s_axi_arvalid(s_axi_arvalid),
      .s_axi_arid(s_axi_arid),
      .s_axi_arlen(s_axi_arlen),
      .s_axi_araddr(s_axi_araddr),
      .s_axi_aruser(s_axi_aruser),
      .s_axi_arready(s_axi_arready),
      .s_axi_rvalid(s_axi_rvalid),
      .s_axi_rid(s_axi_rid),
      .s_axi_rdata(s_axi_rdata),
      .s_axi_rresp(s_axi_rresp),
      .s_axi_rlast(s_axi_rlast),
      .s_axi_ruser(s_axi_ruser),
      .s_axi_rready(s_axi_rready),
      .fetch_en_i(fetch_en),
      .events_o(events_o),
      .spi_clk(spi_clk),
      .spi_csn0(spi_csn[0]),
      .spi_csn1(spi_csn[1]),
      .spi_csn2(spi_csn[2]),
      .spi_csn3(spi_csn[3]),
      .spi_mode(spi_mode),
      .spi_sdo0(spi_sdo0),
      .spi_sdo1(spi_sdo1),
      .spi_sdo2(spi_sdo2),
      .spi_sdo3(spi_sdo3),
      .spi_oe0(spi_oe0),
      .spi_oe1(spi_oe1),
      .spi_oe2(spi_oe2),
      .spi_oe3(spi_oe3),
      .spi_sdi0(spi_sdi0),
      .spi_sdi1(spi_sdi1),
      .spi_sdi2(spi_sdi2),
      .spi_sdi3(spi_sdi3)
  );

  // MEM_ADDR_WIDTH=8 (256B) for fast simulation -- the real FPGA build
  // uses 15 (32KiB); this only changes storage depth, not any timing path.
  // INIT_FILE preloads bytes 0x00,0x01,0x02,0x03,0x10,0x11,... at
  // addresses 0-15 (see integ_preload.mem / the file passed via
  // +define+ below), giving each 32-bit AXI word a distinct, recognizable
  // value once byte-swapped: 0x03020100, 0x13121110, 0x23222120,
  // 0x33323130.
  spi_flash_model_fpga_synt #(
      .MEM_ADDR_WIDTH(8),
      .INIT_FILE("tb_fpga_synt_preload.mem"),
      .PROGRAM_BUSY_CYCLES(4),
      .STATUS_BUSY_CYCLES(4)
  ) flash_model (
      .SCK           (spi_clk),
      .CSNeg         (spi_csn[0]),
      .RESETNeg      (rstn),
      .SI_i          (spi_sdo0),
      .SI_o          (flash_si_o),
      .SO_i          (spi_sdo1),
      .SO_o          (flash_so_o),
      .WPNeg_i       (spi_sdo2),
      .WPNeg_o       (flash_wpneg_o),
      .IO3_RESETNeg_i(spi_sdo3),
      .IO3_RESETNeg_o(flash_io3_o)
  );

  initial clk = 0;
  always #5 clk = ~clk;

  localparam REG_STATUS = 32'h00;
  localparam REG_CLKDIV = 32'h04;
  localparam REG_CS_DEF = 32'h24;
  localparam REG_CS_A_0 = 32'h28;
  localparam REG_CS_M_0 = 32'h2C;
  localparam REG_XIP_CMD = 32'h48;
  localparam REG_XIP_DUM = 32'h4C;
  localparam REG_XIP_ADDRLEN = 32'h50;
  localparam REG_SPICMD = 32'h08;
  localparam REG_SPIADR = 32'h0C;
  localparam REG_SPILEN = 32'h10;
  localparam REG_SPIDUM = 32'h14;
  localparam REG_TXFIFO = 32'h18;
  localparam REG_RXFIFO = 32'h20;

  task axi_write(input [31:0] addr, input [31:0] data);
    begin
      @(posedge clk);
      s_axi_awvalid <= 1;
      s_axi_awaddr  <= addr;
      s_axi_awid    <= 0;
      s_axi_awuser  <= 0;
      s_axi_wvalid  <= 1;
      s_axi_wdata   <= data;
      s_axi_wstrb   <= 4'hF;
      s_axi_wlast   <= 1;
      wait (s_axi_awready && s_axi_wready);
      @(posedge clk);
      s_axi_awvalid <= 0;
      s_axi_wvalid  <= 0;
      s_axi_bready  <= 1;
      wait (s_axi_bvalid);
      @(posedge clk);
      s_axi_bready <= 0;
    end
  endtask

  task axi_read(input [31:0] addr, output [31:0] data);
    begin
      @(posedge clk);
      s_axi_arvalid <= 1;
      s_axi_araddr  <= addr;
      s_axi_arid    <= 0;
      s_axi_arlen   <= 0;
      s_axi_aruser  <= 0;
      wait (s_axi_arready);
      @(posedge clk);
      s_axi_arvalid <= 0;
      s_axi_rready  <= 1;
      wait (s_axi_rvalid);
      data = s_axi_rdata;
      @(posedge clk);
      s_axi_rready <= 0;
    end
  endtask

  // Manual-mode WRITE path (Page Program), mirrored from
  // tb_axi_qspi_controller.sv's flash_cmd/flash_poll_wip/flash_page_program
  // -- this is the exact path where this session's two RTL bugs lived
  // (TXFIFO swacc/.value one-cycle timing, trigger_tx_q/trigger_rx_q
  // latching raw inputs instead of the FSM's own latched trigger_tx_d/
  // trigger_rx_d), and it had never been run against this specific FPGA
  // flash model before -- the existing tests above only cover READ, and
  // tb_spi_flash_model_fpga_synt.sv drives the model directly (bit-bang),
  // bypassing the controller entirely.
  task flash_cmd(input [7:0] cmd);
    axi_write(REG_SPICMD, {24'h0, cmd});
    axi_write(REG_SPILEN, 32'h00000008);
    axi_write(REG_STATUS, 32'h00000100);  // Trigger RX
    wait (dut.op_done);
    axi_write(REG_STATUS, 0);
  endtask

  task flash_poll_wip;
    logic [31:0] status;
    int timeout;
    timeout = 1000;
    forever begin
      axi_write(REG_SPICMD, 32'h00000005);  // RDSR
      axi_write(REG_SPILEN, 32'h00080008);
      axi_write(REG_STATUS, 32'h00000100);  // Trigger RX
      wait (dut.op_done);
      axi_write(REG_STATUS, 0);
      axi_read(REG_RXFIFO, status);
      if ((status & 1) == 0) break;  // WIP bit 0
      #1000;
      timeout--;
      if (timeout == 0) begin
        $fatal(1, "Timeout polling WIP");
        break;
      end
    end
  endtask

  task flash_page_program(input [31:0] addr, input [31:0] data);
    logic [31:0] rdata;
    flash_cmd(8'h06);  // WREN

    axi_write(REG_SPICMD, 32'h00000005);  // RDSR
    axi_write(REG_SPILEN, 32'h00080008);
    axi_write(REG_STATUS, 32'h00000100);
    wait (dut.op_done);
    axi_write(REG_STATUS, 0);
    axi_read(REG_RXFIFO, rdata);
    if ((rdata & 2) == 0) $fatal(1, "[TB] WREN Failed! WEL is 0. Status: %h", rdata);

    axi_write(REG_SPICMD, 32'h00000002);  // PP
    axi_write(REG_SPIADR, addr);
    // Page Program has no dummy phase -- must explicitly clear SPIDUM
    // (see the matching fix/comment in tb_axi_qspi_controller.sv's own
    // flash_page_program(), where a stale nonzero SPIDUM leftover from an
    // earlier Quad/Dual-read test caused the controller to insert an
    // unwanted dummy phase before this task's DATA_TX, which the flash
    // model then wrote to memory as a bogus extra byte). Not currently
    // triggered by any test above (none of them touch SPIDUM), but this
    // task shouldn't depend on that -- it already owns SPICMD/SPIADR/
    // SPILEN itself, so it should own SPIDUM too.
    axi_write(REG_SPIDUM, 32'h00000000);
    axi_write(REG_TXFIFO, data);
    axi_write(REG_SPILEN, 32'h00201808);  // Data=32,Addr=24,Cmd=8
    axi_write(REG_STATUS, 32'h00000200);  // Trigger TX
    wait (dut.op_done);
    axi_write(REG_STATUS, 0);

    flash_poll_wip();
  endtask

  initial begin
    logic [31:0] rd;
    rstn = 0;
    // fetch_en must start (and stay) 0 for these tests: setting it to 1
    // makes the controller's own auto-init FSM run a real RSTEN/RST/
    // WREN/WRSR sequence over the SPI bus before releasing s_axi_aw/
    // wready -- fine on its own, but a real, confirmed issue surfaced
    // when driven as a constant 1 (regs_awready stayed low forever after
    // init completed). tb_axi_qspi_controller.sv's own tests only ever
    // set fetch_en=1 for one narrow, dedicated sub-test; every other test
    // (including this one) leaves it at the reset default of 0.
    fetch_en = 0;
    s_axi_awvalid = 0;
    s_axi_wvalid = 0;
    s_axi_bready = 0;
    s_axi_arvalid = 0;
    s_axi_rready = 0;
    #100;
    rstn = 1;
    #100;

    axi_write(REG_CLKDIV, 32'h00000004);
    axi_write(REG_CS_A_0, 32'h00001000);
    axi_write(REG_CS_M_0, 32'hFFFFF000);
    axi_write(REG_CS_DEF, 32'h00000000);

    $display("=== FPGA flash model integration (INIT_FILE preload) ===");

    // --- Standard Read (0x03), default XIP config ---
    axi_write(REG_XIP_CMD, 32'h00000003);
    axi_write(REG_XIP_DUM, 32'h00000000);
    axi_write(REG_XIP_ADDRLEN, 32'h00000018);
    axi_read(32'h00001000, rd);
    if (rd === 32'h03020100) $display("[TB] 0x03 read PASSED: %h", rd);
    else $display("[TB] 0x03 read FAILED: got %h expected 03020100", rd);

    // --- Fast Read (0x0B), 8 dummy cycles ---
    axi_write(REG_XIP_CMD, 32'h0000000B);
    axi_write(REG_XIP_DUM, 32'h00000008);
    axi_read(32'h00001004, rd);
    if (rd === 32'h13121110) $display("[TB] 0x0B read PASSED: %h", rd);
    else $display("[TB] 0x0B read FAILED: got %h expected 13121110", rd);

    // --- Quad Output Fast Read (0x6B), data_mode=2 addr_mode=0 ---
    axi_write(REG_XIP_CMD, {22'b0, 2'b10, 8'h6B});
    axi_write(REG_XIP_DUM, 32'h00000008);
    axi_read(32'h00001008, rd);
    if (rd === 32'h23222120) $display("[TB] 0x6B read PASSED: %h", rd);
    else $display("[TB] 0x6B read FAILED: got %h expected 23222120", rd);

    // --- 4-beat AXI burst, back to default 0x03 ---
    axi_write(REG_XIP_CMD, 32'h00000003);
    axi_write(REG_XIP_DUM, 32'h00000000);
    begin
      logic [31:0] burst_expected[4];
      int burst_errors;
      burst_errors = 0;
      burst_expected[0] = 32'h03020100;
      burst_expected[1] = 32'h13121110;
      burst_expected[2] = 32'h23222120;
      burst_expected[3] = 32'h33323130;

      @(posedge clk);
      s_axi_arvalid <= 1;
      s_axi_araddr  <= 32'h00001000;
      s_axi_arid    <= 0;
      s_axi_arlen   <= 8'd3;
      s_axi_aruser  <= 0;
      wait (s_axi_arready);
      @(posedge clk);
      s_axi_arvalid <= 0;
      s_axi_rready  <= 1;
      for (int beat = 0; beat <= 3; beat++) begin
        do @(posedge clk); while (!s_axi_rvalid);
        if (s_axi_rdata !== burst_expected[beat]) begin
          burst_errors++;
          $display("[TB] burst beat %0d FAILED: got %h expected %h", beat, s_axi_rdata,
                    burst_expected[beat]);
        end
        if (beat == 3 && !s_axi_rlast) begin
          burst_errors++;
          $display("[TB] burst FAILED: RLAST not asserted on final beat");
        end
      end
      s_axi_rready <= 0;
      if (burst_errors == 0) $display("[TB] 4-beat burst PASSED");
      else $display("[TB] 4-beat burst FAILED: %0d beat error(s)", burst_errors);
    end

    // --- Manual WRITE (Page Program) + memory-mapped READ-back ---
    // TEST_ADDR must stay clear of the INIT_FILE preload footprint
    // (bytes 0x00-0x0F) and within MEM_ADDR_WIDTH=8's 256-byte range.
    begin
      logic [31:0] rdata_wr;
      localparam logic [31:0] TEST_ADDR = 32'h00000040;
      localparam logic [31:0] TEST_DATA = 32'h11223344;

      axi_write(REG_CS_DEF, 32'h00000000);
      flash_page_program(TEST_ADDR, TEST_DATA);
      axi_write(REG_XIP_CMD, 32'h00000003);
      axi_write(REG_XIP_DUM, 32'h00000000);
      axi_read(TEST_ADDR + 32'h1000, rdata_wr);

      // flash_page_program() writes TEST_DATA MSB-first (flash bytes
      // 11,22,33,44); memory-mapped AXI read returns little-endian, i.e.
      // byte-swapped -- same convention as tb_axi_qspi_controller.sv's
      // Test 19.
      if (rdata_wr === 32'h44332211)
        $display("[TB] manual WRITE (Page Program) + memory-mapped READ PASSED: %h", rdata_wr);
      else
        $display("[TB] manual WRITE (Page Program) + memory-mapped READ FAILED: got %h expected 44332211",
                  rdata_wr);
    end

    $display("=== FPGA flash model integration test complete ===");
    $finish;
  end

endmodule
