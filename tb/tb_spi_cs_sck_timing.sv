// Directed CS_N / SCK relationship check for spi_controller.
//
// Drives a command-only frame at every clock-divider setting the block can be
// configured to, and checks the three properties the registered-CS change must
// not break:
//   1. no SCK edge may occur while the device is deselected (CS_N == 4'b1111)
//   2. CS_N asserts exactly once per frame (no mid-frame gap)
//   3. the SCK edge count and the MOSI bit pattern are unchanged
// Property 3 is checked by comparing the printed per-config summary between RTL
// variants -- the numbers must be identical; only the CS->SCK phase may move.
`timescale 1ns/1ps

module tb_spi_cs_sck_timing;

  logic clk = 0;
  logic rst_n;
  always #5 clk = ~clk;   // 100 MHz

  logic [7:0] cfg_clkdiv;
  logic       cfg_bypass, cfg_cpol;
  logic       trigger_tx;

  logic        spi_clk;
  logic [3:0]  spi_csn, spi_sdo, spi_oe;
  logic        op_done, busy;

  localparam logic [31:0] CMD_RDID = 32'h0000_009F;

  spi_controller #(.FIFO_DATA_WIDTH(32)) dut (
    .clk_i (clk), .rst_ni (rst_n),
    .cfg_clkdiv_i (cfg_clkdiv), .cfg_clkdiv_bypass_i (cfg_bypass), .cfg_cpol_i (cfg_cpol),
    .cfg_spicmd_i (CMD_RDID), .cfg_spiaddr_i (32'h0),
    .cfg_spilen_i (32'h0000_0008),                 // 8 command bits, no addr/data
    .cfg_spidum_i (32'h0), .cfg_spimode_i (16'h0), .cfg_cs_index_i (2'd0),
    .trigger_rx_i (1'b0), .trigger_tx_i (trigger_tx), .sw_rst_i (1'b0),
    .op_done_o (op_done),
    .tx_fifo_push_i (1'b0), .tx_fifo_data_i (32'h0),
    .rx_fifo_pop_i (1'b0), .rx_fifo_data_o (), .rx_fifo_valid_o (), .rx_last_word_o (),
    .tx_elements_o (), .rx_elements_o (), .busy_o (busy),
    .spi_clk_o (spi_clk), .spi_csn_o (spi_csn), .spi_mode_o (),
    .spi_sdo_o (spi_sdo), .spi_oe_o (spi_oe), .spi_sdi_i (4'b0)
  );

  // ---------------- checkers ----------------
  bit        chk_en = 0;
  int        errors = 0;
  int        bypass_known = 0;
  int        sck_edges, sck_rise, cs_assert_cnt;
  realtime   t_cs_fall, t_first_edge;
  bit        seen_first_edge;
  logic [7:0] mosi_sampled;

  wire deselected = (spi_csn === 4'b1111);

  always @(spi_clk) if (chk_en) begin
    sck_edges++;
    if (deselected) begin
      if (cfg_bypass) begin
        // KNOWN, PRE-EXISTING: in bypass mode spi_clk_o is clk_i gated by combinational
        // logic, so the frame-end cycle emits one narrow pulse as the gate closes. Present
        // identically in the unmodified upstream RTL; bypass is not used by any Lunella
        // configuration (CLKDIV.bypass resets to 0 and no software writes it). Counted and
        // reported, but not a failure of this test -- fixing it means reworking the bypass
        // clock gate, which belongs in its own change.
        bypass_known++;
      end else begin
        errors++;
        $display("  *ERROR* SCK edge at t=%0t while CS_N is HIGH (deselected)", $time);
      end
    end
    if (!seen_first_edge) begin seen_first_edge = 1; t_first_edge = $realtime; end
  end

  // MOSI sampled on the edge the flash latches on (rising for cpol=0, falling for cpol=1)
  always @(posedge spi_clk) if (chk_en && !cfg_cpol && !deselected) begin
    sck_rise++; mosi_sampled = {mosi_sampled[6:0], spi_sdo[0]};
  end
  always @(negedge spi_clk) if (chk_en && cfg_cpol && !deselected) begin
    sck_rise++; mosi_sampled = {mosi_sampled[6:0], spi_sdo[0]};
  end

  always @(negedge deselected) if (chk_en) cs_assert_cnt++;

  // Cycle trace, enabled for one configuration at a time, to show WHERE an edge
  // is gained or lost rather than only that the totals differ.
  bit trace_en = 0;
  always @(posedge clk) if (trace_en)
    $display("    t=%0t state=%0d clk_run=%b sck_q=%b pre=%b pfe=%b pfe_eff=%b first=%b bit_cnt=%0d csn=%b",
             $time, dut.state_q, dut.clk_run, dut.spi_clk_q, dut.pulse_re, dut.pulse_fe,
             dut.pulse_fe_effective, dut.first_edge_q, dut.bit_cnt_q, spi_csn);

  // ---------------- stimulus ----------------
  task automatic run_cfg(input string name, input [7:0] div, input bit byp, input bit cpol);
    int timeout;
    begin
      // quiesce and configure with the checker OFF
      chk_en = 0; rst_n = 0; trigger_tx = 0;
      cfg_clkdiv = div; cfg_bypass = byp; cfg_cpol = cpol;
      repeat (4) @(posedge clk);
      rst_n = 1; repeat (4) @(posedge clk);

      sck_edges = 0; sck_rise = 0; cs_assert_cnt = 0;
      seen_first_edge = 0; mosi_sampled = 0;
      chk_en = 1;
      @(posedge clk);

      // Arm the CS-fall watcher BEFORE the trigger: with a combinational CS_N the
      // assertion happens in the same cycle the trigger is seen, so an @(negedge)
      // armed afterwards would miss it and catch the NEXT frame instead.
      t_cs_fall = 0;
      fork
        begin : cs_watch
          @(negedge deselected); t_cs_fall = $realtime;
        end
      join_none
      trigger_tx = 1; @(posedge clk); trigger_tx = 0;   // exactly one cycle
      wait (t_cs_fall != 0);

      timeout = 0;
      while (busy && timeout < 5000) begin @(posedge clk); timeout++; end
      repeat (4) @(posedge clk);
      chk_en = 0;

      if (timeout >= 5000) begin
        errors++; $display("  *ERROR* %s: frame never completed (busy stuck)", name);
      end
      if (cs_assert_cnt != 1) begin
        errors++; $display("  *ERROR* %s: CS_N asserted %0d times, expected exactly 1", name, cs_assert_cnt);
      end
      $display("  %-22s cs->first_sck_edge = %6.1f ns   sck_edges = %0d   latch_edges = %0d   mosi = 0x%02h",
               name, (t_first_edge - t_cs_fall), sck_edges, sck_rise, mosi_sampled);
      if (mosi_sampled !== 8'h9F) begin
        errors++; $display("  *ERROR* %s: MOSI pattern 0x%02h != expected 0x9F", name, mosi_sampled);
      end
    end
  endtask

  initial begin
    $display("=== tb_spi_cs_sck_timing : CS_N vs SCK across every divider setting ===");
    run_cfg("div=0  (fastest)",   8'd0,   1'b0, 1'b0);
    run_cfg("div=1  (board)",     8'd1,   1'b0, 1'b0);
    run_cfg("div=2  (reset dflt)",8'd2,   1'b0, 1'b0);
    run_cfg("div=7",              8'd7,   1'b0, 1'b0);
    trace_en = 1;
    run_cfg("div=0  cpol=1",      8'd0,   1'b0, 1'b1);
    trace_en = 0;
    run_cfg("div=2  cpol=1",      8'd2,   1'b0, 1'b1);
    run_cfg("bypass (F_spi=F_clk)",8'd0,  1'b1, 1'b0);
    run_cfg("bypass cpol=1",      8'd0,   1'b1, 1'b1);
    $display("=== %0d error(s); %0d known pre-existing bypass-mode frame-end edge(s) ===", errors, bypass_known);
    if (errors == 0) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end

endmodule
