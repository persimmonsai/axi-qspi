`timescale 1ns / 1ps
// tb_axi_qspi_controller_lane64 -- axi_qspi_controller on a 64-bit AXI bus, driven the way the chiplet's
// PCIe path drives it (2026-09-30 board findings over BAR2):
//   * 32-bit data only in its own lane (the other lane carries junk 0xBAD0BAD0),
//     strobes on that lane only -- no replication, unlike the CVA6;
//   * optionally the W beat BEFORE its AW, with the AW address lines still holding the
//     PREVIOUS write's address (what an interconnect presents between transactions).
// Checks:
//   T1 read lane : a register at offset&4 must read back in the upper lane.
//   T2 write lane: SPIADR (0x0C) and TXFIFO (0x18) written W-first right after a write
//                  whose addr[2] differs must land their own data.
//   T3 push count: one TXFIFO write must push exactly one word.
// Prints "TBQ PASS <check>" / "TBQ FAIL <check>" and a final "TBQ RESULT n/n".
module tb_axi_qspi_controller_lane64;
  localparam int AW = 32, DW = 64, IW = 4, UW = 4;
  logic clk = 0, rstn = 0;
  always #5 clk = ~clk;

  logic          awvalid = 0, awready; logic [IW-1:0] awid = 0; logic [7:0] awlen = 0;
  logic [AW-1:0] awaddr = 0;           logic [UW-1:0] awuser = 0;
  logic          wvalid = 0, wready;   logic [DW-1:0] wdata = 0; logic [DW/8-1:0] wstrb = 0;
  logic          wlast = 0;            logic [UW-1:0] wuser = 0;
  logic          bvalid, bready = 1;   logic [IW-1:0] bid; logic [1:0] bresp; logic [UW-1:0] buser;
  logic          arvalid = 0, arready; logic [IW-1:0] arid = 0; logic [7:0] arlen = 0;
  logic [AW-1:0] araddr = 0;           logic [UW-1:0] aruser = 0;
  logic          rvalid, rready = 1;   logic [IW-1:0] rid; logic [DW-1:0] rdata; logic [1:0] rresp;
  logic          rlast;                logic [UW-1:0] ruser;
  logic [1:0]    events;
  wire spi_clk; wire [3:0] spi_csn; wire [1:0] spi_mode;
  wire sdo0, sdo1, sdo2, sdo3, oe0, oe1, oe2, oe3; wire [3:0] spi_io;
  assign spi_io[0] = oe0 ? sdo0 : 1'bz; assign spi_io[1] = oe1 ? sdo1 : 1'bz;
  assign spi_io[2] = oe2 ? sdo2 : 1'bz; assign spi_io[3] = oe3 ? sdo3 : 1'bz;
  pullup (spi_io[0]); pullup (spi_io[1]); pullup (spi_io[2]); pullup (spi_io[3]);
  wire spi_reset_neg = 1'b1;

  axi_qspi_controller #(.AXI4_ADDRESS_WIDTH(AW), .AXI4_RDATA_WIDTH(DW), .AXI4_WDATA_WIDTH(DW),
                        .AXI4_USER_WIDTH(UW), .AXI4_ID_WIDTH(IW)) dut (
    .s_axi_aclk(clk), .s_axi_aresetn(rstn),
    .s_axi_awvalid(awvalid), .s_axi_awid(awid), .s_axi_awlen(awlen), .s_axi_awaddr(awaddr),
    .s_axi_awuser(awuser), .s_axi_awready(awready),
    .s_axi_wvalid(wvalid), .s_axi_wdata(wdata), .s_axi_wstrb(wstrb), .s_axi_wlast(wlast),
    .s_axi_wuser(wuser), .s_axi_wready(wready),
    .s_axi_bvalid(bvalid), .s_axi_bid(bid), .s_axi_bresp(bresp), .s_axi_buser(buser), .s_axi_bready(bready),
    .s_axi_arvalid(arvalid), .s_axi_arid(arid), .s_axi_arlen(arlen), .s_axi_araddr(araddr),
    .s_axi_aruser(aruser), .s_axi_arready(arready),
    .s_axi_rvalid(rvalid), .s_axi_rid(rid), .s_axi_rdata(rdata), .s_axi_rresp(rresp),
    .s_axi_rlast(rlast), .s_axi_ruser(ruser), .s_axi_rready(rready),
    .fetch_en_i(1'b0), .events_o(events),
    .spi_clk(spi_clk), .spi_csn0(spi_csn[0]), .spi_csn1(spi_csn[1]), .spi_csn2(spi_csn[2]), .spi_csn3(spi_csn[3]),
    .spi_mode(spi_mode), .spi_sdo0(sdo0), .spi_sdo1(sdo1), .spi_sdo2(sdo2), .spi_sdo3(sdo3),
    .spi_oe0(oe0), .spi_oe1(oe1), .spi_oe2(oe2), .spi_oe3(oe3),
    .spi_sdi0(spi_io[0]), .spi_sdi1(spi_io[1]), .spi_sdi2(spi_io[2]), .spi_sdi3(spi_io[3]));

  spi_flash_model flash (.SI(spi_io[0]), .SO(spi_io[1]), .SCK(spi_clk), .CSNeg(spi_csn[0]),
                         .WPNeg(spi_io[2]), .RESETNeg(spi_reset_neg), .IO3_RESETNeg(spi_io[3]));

  // ---- observe every TXFIFO push ----
  int unsigned pushes = 0; logic [31:0] last_push;
  always @(posedge clk) if (rstn && dut.tx_push) begin pushes++; last_push = dut.tx_data[31:0]; end

  // ---- AXI helpers ----
  localparam logic [31:0] JUNK = 32'hBAD0_BAD0;
  function automatic logic [DW-1:0] lane_data(input logic [AW-1:0] a, input logic [31:0] d);
    return a[2] ? {d, JUNK} : {JUNK, d};
  endfunction
  function automatic logic [DW/8-1:0] lane_strb(input logic [AW-1:0] a);
    return a[2] ? 8'hF0 : 8'h0F;
  endfunction
  task automatic wait_b(); do @(posedge clk); while (!bvalid); endtask

  // AW and W presented together (the easy case).
  task automatic wr(input logic [AW-1:0] a, input logic [31:0] d);
    @(posedge clk);
    awaddr <= a; awvalid <= 1; wdata <= lane_data(a, d); wstrb <= lane_strb(a); wlast <= 1; wvalid <= 1;
    fork
      begin do @(posedge clk); while (!awready); awvalid <= 0; end
      begin do @(posedge clk); while (!wready);  wvalid  <= 0; end
    join
    wait_b();
    // address lines keep the last address (awaddr is NOT cleared), as between transactions
  endtask

  // W beat first; its AW follows only after W has been accepted. awaddr still shows the
  // previous write's address while W is accepted.
  task automatic wr_wfirst(input logic [AW-1:0] a, input logic [31:0] d);
    @(posedge clk);
    wdata <= lane_data(a, d); wstrb <= lane_strb(a); wlast <= 1; wvalid <= 1;
    do @(posedge clk); while (!wready); wvalid <= 0;
    awaddr <= a; awvalid <= 1;
    do @(posedge clk); while (!awready); awvalid <= 0;
    wait_b();
  endtask

  task automatic rd(input logic [AW-1:0] a, output logic [31:0] d);
    @(posedge clk); araddr <= a; arvalid <= 1;
    do @(posedge clk); while (!arready); arvalid <= 0;
    while (!rvalid) @(posedge clk);
    d = a[2] ? rdata[63:32] : rdata[31:0];     // the master takes ITS lane
  endtask

  int npass = 0, nfail = 0;
  task automatic chk(input string name, input logic [31:0] got, input logic [31:0] exp);
    if (got === exp) begin npass++; $display("TBQ PASS %-44s got 0x%08h", name, got); end
    else begin nfail++; $display("TBQ FAIL %-44s got 0x%08h want 0x%08h", name, got, exp); end
  endtask

  localparam logic [AW-1:0] STATUS=0, CLKDIV=4, SPICMD=8, SPIADR=12, SPILEN=16, SPIDUM=20, TXFIFO=24, CS_A_0=40;
  logic [31:0] v; int unsigned p0;
  initial begin
    repeat (5) @(posedge clk); rstn = 1;
    wait (dut.init_active === 1'b0); repeat (20) @(posedge clk);
    $display("TBQ info controller init done at %0t", $time);

    // T1 -- read lane. CLKDIV is at 0x04 (upper lane of the 64-bit word).
    wr(CLKDIV, 32'h0000_0033);
    chk("T1a CLKDIV register holds the write", {24'h0, dut.reg_clkdiv}, 32'h33);
    rd(CLKDIV, v);
    chk("T1b CLKDIV (0x04) reads back in its lane", v & 32'hFF, 32'h33);
    wr(CS_A_0, 32'h1234_5678);
    rd(CS_A_0, v);
    chk("T1c CS_A_0 (0x28, lower lane) reads back", v, 32'h1234_5678);

    // T2 -- write lane with W before AW, stale address from a write of the other lane.
    wr(SPICMD, 32'h0000_0002);                         // aligned (addr[2]=0) write first
    wr_wfirst(SPIADR, 32'h00AB_CDEF);                  // then SPIADR (addr[2]=1), W first
    chk("T2a SPIADR (0x0C) W-first after aligned write", dut.reg_spiaddr, 32'h00AB_CDEF);
    wr(SPIDUM, 32'h0000_0000);                         // addr[2]=1 write
    p0 = pushes;
    wr_wfirst(TXFIFO, 32'hC0DE_5A5A);                  // then TXFIFO (addr[2]=0), W first
    repeat (5) @(posedge clk);
    chk("T2b TXFIFO (0x18) W-first after SPIDUM: pushed data", last_push, 32'hC0DE_5A5A);

    // T3 -- one TXFIFO write, one push (AW+W together, clean case)
    wr(SPICMD, 32'h0000_0002);
    p0 = pushes;
    wr(TXFIFO, 32'h1111_2222);
    repeat (5) @(posedge clk);
    chk("T3a one TXFIFO write -> pushes", pushes - p0, 1);
    chk("T3b pushed data", last_push, 32'h1111_2222);

    $display("TBQ RESULT %0d/%0d passed", npass, npass + nfail);
    $finish;
  end
  initial begin #20ms; $display("TBQ FAIL timeout"); $finish; end
endmodule
