
`include "axi/assign.svh"
`include "axi/typedef.svh"

module axi_qspi_controller #(
    parameter int unsigned AXI4_ADDRESS_WIDTH = 32,
    parameter int unsigned AXI4_RDATA_WIDTH   = 32,
    parameter int unsigned AXI4_WDATA_WIDTH   = 32,
    parameter int unsigned AXI4_ID_WIDTH      = 4,
    parameter int unsigned AXI4_USER_WIDTH    = 4,
    parameter int unsigned BUFFER_DEPTH       = 16
) (
    input logic s_axi_aclk,
    input logic s_axi_aresetn,

    // AXI4 Slave Interface
    input  logic                          s_axi_awvalid,
    input  logic [     AXI4_ID_WIDTH-1:0] s_axi_awid,
    input  logic [                   7:0] s_axi_awlen,
    input  logic [AXI4_ADDRESS_WIDTH-1:0] s_axi_awaddr,
    input  logic [   AXI4_USER_WIDTH-1:0] s_axi_awuser,
    output logic                          s_axi_awready,

    input  logic                          s_axi_wvalid,
    input  logic [  AXI4_WDATA_WIDTH-1:0] s_axi_wdata,
    input  logic [AXI4_WDATA_WIDTH/8-1:0] s_axi_wstrb,
    input  logic                          s_axi_wlast,
    input  logic [   AXI4_USER_WIDTH-1:0] s_axi_wuser,
    output logic                          s_axi_wready,

    output logic                       s_axi_bvalid,
    output logic [  AXI4_ID_WIDTH-1:0] s_axi_bid,
    output logic [                1:0] s_axi_bresp,
    output logic [AXI4_USER_WIDTH-1:0] s_axi_buser,
    input  logic                       s_axi_bready,

    input  logic                          s_axi_arvalid,
    input  logic [     AXI4_ID_WIDTH-1:0] s_axi_arid,
    input  logic [                   7:0] s_axi_arlen,
    input  logic [AXI4_ADDRESS_WIDTH-1:0] s_axi_araddr,
    input  logic [   AXI4_USER_WIDTH-1:0] s_axi_aruser,
    output logic                          s_axi_arready,

    output logic                        s_axi_rvalid,
    output logic [   AXI4_ID_WIDTH-1:0] s_axi_rid,
    output logic [AXI4_RDATA_WIDTH-1:0] s_axi_rdata,
    output logic [                 1:0] s_axi_rresp,
    output logic                        s_axi_rlast,
    output logic [ AXI4_USER_WIDTH-1:0] s_axi_ruser,
    input  logic                        s_axi_rready,

    // SPI Interface
    output logic       spi_clk,
    output logic       spi_csn0,
    output logic       spi_csn1,
    output logic       spi_csn2,
    output logic       spi_csn3,
    output logic [1:0] spi_mode,
    output logic       spi_sdo0,
    output logic       spi_sdo1,
    output logic       spi_sdo2,
    output logic       spi_sdo3,
    output logic       spi_oe0,
    output logic       spi_oe1,
    output logic       spi_oe2,
    output logic       spi_oe3,
    input  logic       spi_sdi0,
    input  logic       spi_sdi1,
    input  logic       spi_sdi2,
    input  logic       spi_sdi3,

    input  logic       fetch_en_i,
    output logic [1:0] events_o
);

  // --- Sub-modules Signal Declarations ---
  // --- Sub-modules Signal Declarations ---
  logic [ 7:0] reg_clkdiv;
  logic        reg_clkdiv_bypass;
  logic        reg_cpol;
  logic [31:0] reg_spicmd;
  logic [31:0] reg_spiaddr;
  logic [31:0] reg_spilen;
  logic [31:0] reg_spidum;
  logic [31:0] reg_cs_def;
  logic [31:0] reg_cs_a_0;
  logic [31:0] reg_cs_m_0;
  logic [31:0] reg_cs_a_1;
  logic [31:0] reg_cs_m_1;
  logic [31:0] reg_cs_a_2;
  logic [31:0] reg_cs_m_2;
  logic [31:0] reg_cs_a_3;
  logic [31:0] reg_cs_m_3;

  logic trig_rx, trig_tx, sw_rst;
  logic                        op_done;

  // Auto-Init Signals
  logic                        init_active;
  logic [                31:0] init_spicmd;
  logic [                31:0] init_spilen;
  logic                        init_trig_tx;
  logic                        init_tx_push;
  logic [                31:0] init_tx_data;

  logic                        tx_push;
  logic [AXI4_RDATA_WIDTH-1:0] tx_data;
  logic                        rx_pop;
  logic [AXI4_RDATA_WIDTH-1:0] rx_data;
  logic                        rx_valid;
  logic [3:0] tx_lvl, rx_lvl;
  logic mem_pop;

  logic [3:0] spi_sdo_full, spi_oe_full;
  logic [3:0] spi_sdi_full;

  // Mapping SDI
  assign spi_sdi_full = {spi_sdi3, spi_sdi2, spi_sdi1, spi_sdi0};
  assign spi_sdo0 = spi_sdo_full[0];
  assign spi_sdo1 = spi_sdo_full[1];
  assign spi_sdo2 = spi_sdo_full[2];
  assign spi_sdo3 = spi_sdo_full[3];

  assign spi_oe0 = spi_oe_full[0];
  assign spi_oe1 = spi_oe_full[1];
  assign spi_oe2 = spi_oe_full[2];
  assign spi_oe3 = spi_oe_full[3];

  // CS Mux (Future expansion)
  // assign spi_csn1 = 1;
  // assign spi_csn2 = 1;
  // assign spi_csn3 = 1;
  // Handled by controller now.

  // --- Address Decoding / Muxing ---

  // AXI Control Registers at 0x000 - 0xFFF
  // Memory Mapped region at 0x1000+ (mapped to 0x0 in Flash) 

  // --- Request Muxing ---
  logic reg_sel, mem_sel;
  assign reg_sel = (s_axi_araddr < 32'h1000);
  assign mem_sel = ~reg_sel;

  // For Writes, we assume ONLY Registers (Read-Only Memory Map).
  // So AW always Regs.

  // Internal AXI-Lite signals for Regs
  // Instantiate `axi_qspi_regs` and connect manually.

  // Interface logic for axi_qspi_regs
  typedef struct packed {
    logic [AXI4_ADDRESS_WIDTH-1:0] addr;
    logic [2:0] prot;
    logic [AXI4_ID_WIDTH-1:0] id;
  } aw_t;

  typedef struct packed {
    logic [AXI4_WDATA_WIDTH-1:0]   data;
    logic [AXI4_WDATA_WIDTH/8-1:0] strb;
  } w_t;

  typedef struct packed {
    logic [AXI4_ADDRESS_WIDTH-1:0] addr;
    logic [2:0] prot;
    logic [AXI4_ID_WIDTH-1:0] id;
  } ar_t;

  // REGS Connections
  logic [AXI4_ADDRESS_WIDTH-1:0] regs_awaddr;
  logic regs_awvalid, regs_awready;
  logic [AXI4_WDATA_WIDTH-1:0] regs_wdata;
  logic regs_wvalid, regs_wready;
  logic regs_bvalid, regs_bready;

  logic [AXI4_ADDRESS_WIDTH-1:0] regs_araddr;
  logic regs_arvalid, regs_arready;
  logic [AXI4_RDATA_WIDTH-1:0] regs_rdata;
  logic regs_rvalid, regs_rready;

  // MEM Connections (Read Only)
  logic [AXI4_ADDRESS_WIDTH-1:0] mem_araddr;
  logic mem_arvalid, mem_arready;
  logic [AXI4_RDATA_WIDTH-1:0] mem_rdata;
  logic mem_rvalid, mem_rready;
  logic mem_rlast;
  logic [AXI4_ID_WIDTH-1:0] mem_rid;
  logic [AXI4_ID_WIDTH-1:0] mem_rid_latched;  // Unused if using mem_rid directly in FSM

  // --- Demux Logic for AR ---
  assign s_axi_arready = init_active ? 1'b0 : (reg_sel ? regs_arready : mem_arready);

  assign regs_arvalid = s_axi_arvalid && reg_sel;
  assign regs_araddr = s_axi_araddr;

  assign mem_arvalid = s_axi_arvalid && mem_sel;
  assign mem_araddr = s_axi_araddr;

  // --- Mux Logic for R ---
  // Problem: R channel doesn't know who granted AR.
  // Solution: Keep track of ID or order?
  // AXI4 implies ordering per ID.
  // Simple approach: Registered "In Flight" bit or ID tracking.
  // If we support interleaving, we need complex logic.
  // Assuming blocking single-transaction for now or strictly ordered.
  // Let's use a simple Arbiter response.
  // Actually, simple mux based on who is valid?
  assign s_axi_rvalid = regs_rvalid | mem_rvalid;
  assign s_axi_rdata = (regs_rvalid) ? regs_rdata : mem_rdata;
  assign s_axi_rlast = (regs_rvalid) ? 1'b1 : mem_rlast;
  assign s_axi_rid = (regs_rvalid) ? regs_resp.r.id : mem_rid;
  assign s_axi_rresp = (regs_rvalid) ? regs_resp.r.resp : 2'b00;  // OKAY

  assign regs_rready = s_axi_rready;  // Broadcast ready? Danger.
  assign mem_rready = s_axi_rready;  // Only the valid one should take it.

  // Better Mux:
  // If regs_rvalid, route regs. If mem_rvalid, route mem.
  // AXI spec says master cannot switch ready based on valid?
  // Wait, Slave output.

  // --- Instance: AXI SPI REGS ---

  // Define structs to match axi_qspi_regs interface

  typedef logic [AXI4_ADDRESS_WIDTH-1:0] addr_t;
  typedef logic [AXI4_WDATA_WIDTH-1:0] data_t;
  typedef logic [AXI4_WDATA_WIDTH/8-1:0] strb_t;

  // Define structs for axi_qspi_regs

  typedef struct packed {
    logic [AXI4_ID_WIDTH-1:0]   id;
    addr_t                      addr;
    logic [7:0]                 len;
    logic [2:0]                 size;
    logic [1:0]                 burst;
    logic                       lock;
    logic [3:0]                 cache;
    logic [2:0]                 prot;
    logic [3:0]                 qos;
    logic [3:0]                 region;
    logic [AXI4_USER_WIDTH-1:0] user;
  } axi_ar_t;

  typedef struct packed {
    logic [AXI4_ID_WIDTH-1:0]   id;
    addr_t                      addr;
    // ... (Same for AW)
    logic [7:0]                 len;
    logic [2:0]                 size;
    logic [1:0]                 burst;
    logic                       lock;
    logic [3:0]                 cache;
    logic [2:0]                 prot;
    logic [3:0]                 qos;
    logic [3:0]                 region;
    logic [AXI4_USER_WIDTH-1:0] user;
  } axi_aw_t;

  typedef struct packed {
    data_t data;
    strb_t strb;
    logic last;
    logic [AXI4_USER_WIDTH-1:0] user;
  } axi_w_t;

  typedef struct packed {
    logic aw_valid;
    axi_aw_t aw;
    logic w_valid;
    axi_w_t w;
    logic b_ready;
    logic ar_valid;
    axi_ar_t ar;
    logic r_ready;
  } axi_req_t;

  typedef struct packed {
    logic aw_ready;
    logic ar_ready;
    logic w_ready;
    logic b_valid;
    struct packed {
      logic [AXI4_ID_WIDTH-1:0] id;
      logic [1:0] resp;
      logic [AXI4_USER_WIDTH-1:0] user;
    } b;
    logic r_valid;
    struct packed {
      logic [AXI4_ID_WIDTH-1:0] id;
      data_t data;
      logic [1:0] resp;
      logic last;
      logic [AXI4_USER_WIDTH-1:0] user;
    } r;
  } axi_resp_t;

  axi_req_t  regs_req;
  axi_resp_t regs_resp;

  // Assign REGSReq
  always_comb begin
    regs_req = '0;
    // AW
    regs_req.aw_valid = s_axi_awvalid;  // Always valid to regs
    regs_req.aw.addr = s_axi_awaddr;
    regs_req.aw.id = s_axi_awid;

    // W
    regs_req.w_valid = s_axi_wvalid;
    regs_req.w.data = s_axi_wdata;
    regs_req.w.strb = s_axi_wstrb;
    regs_req.w.last = s_axi_wlast;

    // B
    regs_req.b_ready = s_axi_bready;

    // AR (Filtered)
    regs_req.ar_valid = regs_arvalid;
    regs_req.ar.addr = regs_araddr;
    regs_req.ar.id = s_axi_arid;

    // R
    regs_req.r_ready = regs_rready;
  end

  // Assign Resp back to flat
  assign regs_awready = regs_resp.aw_ready;
  assign regs_wready = regs_resp.w_ready;

  assign s_axi_awready = init_active ? 1'b0 : regs_awready; // Always route Write signals to Regs
  assign s_axi_wready  = init_active ? 1'b0 : regs_wready;

  assign s_axi_bvalid = regs_resp.b_valid;
  assign s_axi_bid    = regs_resp.b.id;
  assign s_axi_bresp  = regs_resp.b.resp;
  assign s_axi_buser  = regs_resp.b.user;

  assign regs_rvalid = regs_resp.r_valid;
  assign regs_rdata  = regs_resp.r.data;
  assign regs_arready = regs_resp.ar_ready;

  // --- Generated Register Block Integration ---

  import axi_qspi_regs_pkg::*;
  axi_qspi_regs__in_t  hwif_in;
  axi_qspi_regs__out_t hwif_out;

  // Signal Mapping using hwif structs
  assign hwif_in.STATUS.rx_cnt.next = rx_lvl;
  assign hwif_in.STATUS.tx_cnt.next = tx_lvl;
  assign hwif_in.RXFIFO.data.next = rx_data[31:0];  // Truncate if wider

  assign reg_clkdiv = hwif_out.CLKDIV.div.value;
  assign reg_clkdiv_bypass = hwif_out.CLKDIV.bypass.value;
  assign reg_cpol = hwif_out.CLKDIV.cpol.value;
  assign reg_spicmd = hwif_out.SPICMD.cmd.value;
  assign reg_spiaddr = hwif_out.SPIADR.addr.value;
  assign reg_spilen = hwif_out.SPILEN.len.value;
  assign reg_spidum = hwif_out.SPIDUM.dum.value;
  assign reg_cs_def = hwif_out.CS_DEF.cs.value;
  assign reg_cs_a_0 = hwif_out.CS_A_0.val.value;
  assign reg_cs_m_0 = hwif_out.CS_M_0.val.value;
  assign reg_cs_a_1 = hwif_out.CS_A_1.val.value;
  assign reg_cs_m_1 = hwif_out.CS_M_1.val.value;
  assign reg_cs_a_2 = hwif_out.CS_A_2.val.value;
  assign reg_cs_m_2 = hwif_out.CS_M_2.val.value;
  assign reg_cs_a_3 = hwif_out.CS_A_3.val.value;
  assign reg_cs_m_3 = hwif_out.CS_M_3.val.value;

  assign trig_rx = hwif_out.STATUS.trig_rx.value;
  assign trig_tx = hwif_out.STATUS.trig_tx.value;
  assign sw_rst = hwif_out.STATUS.sw_rst.value;

  assign tx_push = hwif_out.TXFIFO.data.swacc;
  assign tx_data = {{(AXI4_RDATA_WIDTH - 32) {1'b0}}, hwif_out.TXFIFO.data.value};  // Zero extend
  assign rx_pop = hwif_out.RXFIFO.data.swacc | mem_pop;

  // Manual assignments for AXI interface adaptation

  // Adapter Signals
  logic s_axil_awready_flat;
  logic s_axil_wready_flat;
  logic s_axil_bvalid_flat;
  logic [1:0] s_axil_bresp_flat;
  logic s_axil_arready_flat;
  logic s_axil_rvalid_flat;
  logic [31:0] s_axil_rdata_flat;
  logic [1:0] s_axil_rresp_flat;

  // ID Reflection Logic (Simple Latch - supports 1 outstanding transaction context)
  // Ideally use a FIFO for full AXI compliance with pipelining.
  logic [AXI4_ID_WIDTH-1:0] regs_awid_latch;
  logic [AXI4_ID_WIDTH-1:0] regs_arid_latch;

  always_ff @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
    if (!s_axi_aresetn) begin
      regs_awid_latch <= '0;
      regs_arid_latch <= '0;
    end else begin
      if (regs_req.aw_valid && s_axil_awready_flat) regs_awid_latch <= regs_req.aw.id;
      if (regs_req.ar_valid && s_axil_arready_flat) regs_arid_latch <= regs_req.ar.id;
    end
  end

  // Assign Outputs to Struct
  assign regs_resp.aw_ready = s_axil_awready_flat;
  assign regs_resp.w_ready  = s_axil_wready_flat;
  assign regs_resp.b_valid  = s_axil_bvalid_flat;
  assign regs_resp.b.resp   = s_axil_bresp_flat;
  assign regs_resp.b.id     = regs_awid_latch;  // Return latched ID
  assign regs_resp.b.user   = '0;

  assign regs_resp.ar_ready = s_axil_arready_flat;
  assign regs_resp.r_valid  = s_axil_rvalid_flat;
  assign regs_resp.r.resp   = s_axil_rresp_flat;
  assign regs_resp.r.data   = {{(AXI4_RDATA_WIDTH - 32) {1'b0}}, s_axil_rdata_flat};
  assign regs_resp.r.last   = 1'b1;  // AXI-Lite is always single beat
  assign regs_resp.r.id     = regs_arid_latch;  // Return latched ID
  assign regs_resp.r.user   = '0;

  axi_qspi_regs u_axiregs (
      .clk(s_axi_aclk),
      .rst(!s_axi_aresetn),

      .s_axil_awvalid(regs_req.aw_valid),
      .s_axil_awready(s_axil_awready_flat),
      .s_axil_awaddr (regs_req.aw.addr[6:0]),
      .s_axil_awprot (regs_req.aw.prot),

      .s_axil_wvalid(regs_req.w_valid),
      .s_axil_wready(s_axil_wready_flat),
      .s_axil_wdata (regs_req.w.data[31:0]),
      .s_axil_wstrb (regs_req.w.strb[3:0]),

      .s_axil_bvalid(s_axil_bvalid_flat),
      .s_axil_bready(regs_req.b_ready),
      .s_axil_bresp (s_axil_bresp_flat),

      .s_axil_arvalid(regs_req.ar_valid),
      .s_axil_arready(s_axil_arready_flat),
      .s_axil_araddr (regs_req.ar.addr[6:0]),
      .s_axil_arprot (regs_req.ar.prot),

      .s_axil_rvalid(s_axil_rvalid_flat),
      .s_axil_rready(regs_req.r_ready),
      .s_axil_rdata (s_axil_rdata_flat),
      .s_axil_rresp (s_axil_rresp_flat),

      .hwif_in (hwif_in),
      .hwif_out(hwif_out)
  );



  // --- SPI MEM Controller (Direct Access) ---
  // Simple state machine to translate AR -> SPI Read
  // Arbitrate between Regs and Mem for SPI Controller access.

  logic mem_spi_busy;
  logic mem_spi_start;
  logic [31:0] mem_spi_addr;
  logic [31:0] mem_rdata_latched;
  logic mem_rvalid_latched;

  // Arbiter Logic
  logic arb_reg_grant, arb_mem_grant;
  // Priority to Registers? OR Priority to Mem?
  // Regs need immediate status. Mem can wait.
  // Assume Reg trigger is explicit.
  logic spi_busy;
  assign spi_busy = (u_spictrl.state_q != 0);
  // Added op_done output to controller.

  // Controller Mux inputs
  logic [31:0] ctrl_spicmd, ctrl_spiaddr, ctrl_spilen, ctrl_spidum;
  logic ctrl_trig_rx, ctrl_trig_tx;

  // We assume Mem Access = XIP Read (Std Read 0x03)

  // Mem Access FSM Types
  typedef enum logic [1:0] {
    M_IDLE,
    M_WAIT,
    M_DONE
  } m_state_t;
  m_state_t m_state;

  // Mux logic for SPI Controller inputs
  logic     mux_sel;
  assign mux_sel      = (mem_spi_start || m_state == M_WAIT);

  // Use CMD 03h (3-byte Read) for Memory Mapped Access (Flash Model Limit)
  assign ctrl_spicmd  = (mux_sel) ? 32'h03 : reg_spicmd;
  // Pass address directly (Controller handles 24-bit truncation if needed)
  assign ctrl_spiaddr = (mux_sel) ? mem_spi_addr : reg_spiaddr;
  // 32-bit Data (0x20), 24-bit Addr (0x18), 8-bit Cmd (0x08).
  assign ctrl_spilen  = (mux_sel) ? (32'h00001808 | (AXI4_RDATA_WIDTH << 16)) : reg_spilen;
  assign ctrl_spidum  = (mux_sel) ? 32'h00000000 : reg_spidum;

  assign ctrl_trig_rx = (mem_spi_start) ? 1'b1 : trig_rx;  // Trigger needs pulse.
  assign ctrl_trig_tx = (mem_spi_start) ? 1'b0 : trig_tx;

  // Chip Select Decoding
  // Logic: 
  // If Config Access (Regs), we assume CS0 (or use default?). 
  // Wait, direct command issue via regs usually implies CS0 unless specified.
  // We can use reg_cs_def for manual commands.
  // For Memory Mapped: Decode Address.
  // 
  // CS0: (Addr & Mask0) == Base0
  // CS1: (Addr & Mask1) == Base1
  // Else: Default (reg_cs_def)

  logic [ 1:0] cs_index;
  logic [31:0] decode_addr;

  // Flash Base Address in AXI Map is 0x1000.
  // s_axi_araddr is the full AXI address.
  // Mask check should be against offset or full addr?
  // Let's check full AXI address for flexibility. 
  // User configures: Base=0x1000, Mask=0xFFFFF000.

  assign decode_addr = (mux_sel) ? s_axi_araddr : 32'h0; // For Reg access, address is irrelevant effectively? 
  // No, for manual commands, we use reg_cs_def.

  // Decoded CS from current ARADDR (combinational)
  logic [1:0] ar_cs_index;
  always_comb begin
    if ((s_axi_araddr & reg_cs_m_0) == reg_cs_a_0) ar_cs_index = 0;
    else if ((s_axi_araddr & reg_cs_m_1) == reg_cs_a_1) ar_cs_index = 1;
    else if ((s_axi_araddr & reg_cs_m_2) == reg_cs_a_2) ar_cs_index = 2;
    else if ((s_axi_araddr & reg_cs_m_3) == reg_cs_a_3) ar_cs_index = 3;
    else ar_cs_index = reg_cs_def[1:0];
  end

  logic [1:0] mem_cs_index_latched;

  always_comb begin
    if (mux_sel) begin
      // Memory Mapped Access - Use Latched Value
      cs_index = mem_cs_index_latched;
    end else begin
      // Manual Command - Use Register
      cs_index = reg_cs_def[1:0];
    end
  end

  assign mem_pop = (m_state == M_DONE && rx_valid && mem_rready);

  // SPI Controller
  spi_controller #(
      .FIFO_DATA_WIDTH(AXI4_RDATA_WIDTH)
  ) u_spictrl (
      .clk_i(s_axi_aclk),
      .rst_ni(s_axi_aresetn),
      .cfg_clkdiv_i(init_active ? 8'h02 : reg_clkdiv),
      .cfg_clkdiv_bypass_i(init_active ? 1'b0 : reg_clkdiv_bypass),
      .cfg_cpol_i(init_active ? 1'b0 : reg_cpol),
      .cfg_spicmd_i(init_active ? init_spicmd : ctrl_spicmd),
      .cfg_spiaddr_i(init_active ? 32'd0 : ctrl_spiaddr),
      .cfg_spilen_i(init_active ? init_spilen : ctrl_spilen),
      .cfg_spidum_i(init_active ? 32'd0 : ctrl_spidum),
      .cfg_cs_index_i(init_active ? 2'b00 : ar_cs_index),

      .trigger_rx_i(init_active ? 1'b0 : ctrl_trig_rx),
      .trigger_tx_i(init_active ? init_trig_tx : ctrl_trig_tx),
      .sw_rst_i(sw_rst),
      .op_done_o(op_done),

      .tx_fifo_push_i(init_active ? init_tx_push : tx_push),
      .tx_fifo_data_i(init_active ? init_tx_data : tx_data),

      .rx_fifo_pop_i  (rx_pop),
      .rx_fifo_data_o (rx_data),
      .rx_fifo_valid_o(rx_valid),
      .tx_elements_o  (tx_lvl),
      .rx_elements_o  (rx_lvl),

      .spi_clk_o (spi_clk),
      .spi_csn_o ({spi_csn3, spi_csn2, spi_csn1, spi_csn0}),
      .spi_mode_o(spi_mode),
      .spi_sdo_o (spi_sdo_full),
      .spi_oe_o  (spi_oe_full),
      .spi_sdi_i (spi_sdi_full)
  );

  // --- Auto-Initialization FSM ---
  typedef enum logic [3:0] {
    INIT_IDLE,
    INIT_RSTEN_CMD,
    INIT_RSTEN_WAIT,
    INIT_RST_CMD,
    INIT_RST_WAIT,
    INIT_WREN_CMD,
    INIT_WREN_WAIT,
    INIT_WRSR_PUSH,   // Push data to FIFO
    INIT_WRSR_CMD,
    INIT_WRSR_WAIT,
    INIT_DONE
  } init_state_t;

  init_state_t init_state, init_next;
  // Signals moved to top of module

  // Output Blocking Logic
  // Gating Ready signals when Init is Active
  // Using explicit blocking on the flat signals before they go to struct or assignment

  // Actually, we can just mask the ready signals being assigned to outputs/regs
  // s_axi_awready => blocked
  // s_axi_arready => blocked

  // Note: We need to override the assignment to s_axi_awready/arready.
  // Currently:
  // assign s_axi_awready = regs_awready;
  // assign s_axi_arready = (reg_sel) ? regs_arready : mem_arready;

  // We will modify those assignments below (or above if they are already there). 
  // Since they are already defined, we should wrap them or change them.
  // Wait, I cannot redefine 'assign' without removing old ones.
  // I will assume I need to replace those lines too.

  always_ff @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
    if (!s_axi_aresetn) begin
      init_state <= INIT_IDLE;
    end else begin
      init_state <= init_next;
    end
  end

  always_comb begin
    init_next = init_state;
    init_active = 1'b1;  // Default true except IDLE and DONE? 
                         // Actually, allow register access in DONE.

    init_spicmd = 0;
    init_spilen = 0;
    init_trig_tx = 0;
    init_tx_push = 0;
    init_tx_data = 0;

    case (init_state)
      INIT_IDLE: begin
        if (fetch_en_i) init_next = INIT_RSTEN_CMD;
        else init_next = INIT_DONE;
        init_active = 0;  // Not active yet? Or active to block?
                          // If we are in reset, we are effectively blocked anyway.
                          // But immediately after reset, if fetch_en_i is high, we go to CMD.
                          // So in IDLE, if we interpret as "Not initialized yet but decided to skip", 
                          // we should be careful. 
                          // Let's say init_active is High until INIT_DONE.
        // init_active = fetch_en_i;
        init_active = 0;
      end

      // 1. Reset Enable (66h)
      INIT_RSTEN_CMD: begin
        init_spicmd = 32'h66;
        init_spilen = 32'h00000008;  // 8 bit cmd
        init_trig_tx = 1'b1;
        init_next = INIT_RSTEN_WAIT;
      end

      INIT_RSTEN_WAIT: begin
        init_spicmd = 32'h66;
        init_spilen = 32'h00000008;
        if (op_done) init_next = INIT_RST_CMD;
      end

      // 2. Reset (99h)
      INIT_RST_CMD: begin
        init_spicmd = 32'h99;
        init_spilen = 32'h00000008;
        init_trig_tx = 1'b1;
        init_next = INIT_RST_WAIT;
      end

      INIT_RST_WAIT: begin
        init_spicmd = 32'h99;
        init_spilen = 32'h00000008;
        if (op_done) init_next = INIT_WREN_CMD;
      end

      // 3. Write Enable (06h)
      INIT_WREN_CMD: begin
        init_spicmd = 32'h06;
        init_spilen = 32'h00000008;
        init_trig_tx = 1'b1;
        init_next = INIT_WREN_WAIT;
      end

      INIT_WREN_WAIT: begin
        init_spicmd = 32'h06;
        init_spilen = 32'h00000008;
        if (op_done) init_next = INIT_WRSR_PUSH;
      end

      // 4. Write Status Register (01h) + Data (40h for Quad Enable)
      INIT_WRSR_PUSH: begin
        // Push data to FIFO first
        init_tx_push = 1'b1;
        init_tx_data = 32'h40;  // QE bit
        init_next = INIT_WRSR_CMD;
      end

      INIT_WRSR_CMD: begin
        init_spicmd = 32'h01;
        init_spilen = 32'h00080008;  // 8 bit cmd, 8 bit data
        init_trig_tx = 1'b1;
        init_next = INIT_WRSR_WAIT;
      end

      INIT_WRSR_WAIT: begin
        init_spicmd = 32'h01;
        init_spilen = 32'h00080008;
        if (op_done) init_next = INIT_DONE;
      end

      INIT_DONE: begin
        init_active = 1'b0;
        init_next   = INIT_DONE;
      end

      default: init_next = INIT_IDLE;
    endcase
  end

  always_ff @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
    if (!s_axi_aresetn) begin
      m_state <= M_IDLE;
      mem_arready <= 0;
      mem_rvalid <= 0;
      mem_rdata <= 0;
      mem_spi_start <= 0;
      mem_rid <= 0;
      mem_rlast <= 0;
      mem_cs_index_latched <= 0;
    end else begin
      // Defaults
      mem_arready   <= 0;
      mem_spi_start <= 0;

      case (m_state)
        M_IDLE: begin
          if (mem_arvalid && !spi_busy) begin  // Wait for idle
            mem_arready <= 1;  // Ack AR
            m_state <= M_WAIT;
            mem_spi_addr <= mem_araddr - 32'h1000;
            mem_spi_start <= 1;
            mem_spi_addr <= mem_araddr - 32'h1000;
            mem_spi_start <= 1;
            mem_rid <= s_axi_arid;  // Latch ID
            mem_cs_index_latched <= ar_cs_index;  // Latch CS Index
          end
        end

        M_WAIT: begin
          if (op_done) begin
            m_state <= M_DONE;
            // Byte Swap for AXI (LE) - Parameterized
            for (int i = 0; i < AXI4_RDATA_WIDTH / 8; i++) begin
              mem_rdata[i*8+:8] <= rx_data[(AXI4_RDATA_WIDTH/8-1-i)*8+:8];
            end
          end
        end

        M_DONE: begin
          mem_rvalid <= 1;
          if (mem_rready) begin
            mem_rvalid <= 0;
            m_state <= M_IDLE;
          end
        end
      endcase
    end
  end

  assign events_o = 0;

endmodule
