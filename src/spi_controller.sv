

module spi_controller #(
    parameter int unsigned FIFO_DATA_WIDTH = 32
) (
    input logic clk_i,
    input logic rst_ni,

    // Configuration
    input logic [ 7:0] cfg_clkdiv_i,
    input logic        cfg_clkdiv_bypass_i,
    input logic        cfg_cpol_i,
    input logic [31:0] cfg_spicmd_i,
    input logic [31:0] cfg_spiaddr_i,
    input logic [31:0] cfg_spilen_i,         // [7:0] cmd, [15:8] addr, [31:16] data (bits)
    input logic [31:0] cfg_spidum_i,
    input logic [ 1:0] cfg_cs_index_i,       // Selected CS [0..3]

    // Control
    input  logic trigger_rx_i,
    input  logic trigger_tx_i,
    input  logic sw_rst_i,
    output logic op_done_o,

    // Data Interface (To/From Registers)
    input logic                       tx_fifo_push_i,
    input logic [FIFO_DATA_WIDTH-1:0] tx_fifo_data_i,

    input  logic                       rx_fifo_pop_i,
    output logic [FIFO_DATA_WIDTH-1:0] rx_fifo_data_o,
    output logic                       rx_fifo_valid_o,

    // FIFO Status for Regs
    output logic [3:0] tx_elements_o,
    output logic [3:0] rx_elements_o,

    // SPI Pad Interface
    output logic       spi_clk_o,
    output logic [3:0] spi_csn_o,   // Active Low, 4-bit vector
    output logic [1:0] spi_mode_o,  // 00: Std, 01: Dual (not used in TB?), 10: Quad
    output logic [3:0] spi_sdo_o,
    output logic [3:0] spi_oe_o,
    input  logic [3:0] spi_sdi_i
);

  // --- FIFO Implementation ---
  logic [FIFO_DATA_WIDTH-1:0] tx_fifo[15:0];
  logic [3:0] tx_wr_ptr, tx_rd_ptr;
  logic [4:0] tx_count;

  logic [FIFO_DATA_WIDTH-1:0] rx_fifo[15:0];
  logic [3:0] rx_wr_ptr, rx_rd_ptr;
  logic [                4:0] rx_count;

  logic                       tx_pop_enable;
  logic                       rx_push_enable;
  logic [FIFO_DATA_WIDTH-1:0] rx_push_data;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      tx_wr_ptr <= 0;
      tx_rd_ptr <= 0;
      tx_count  <= 0;
      rx_wr_ptr <= 0;
      rx_rd_ptr <= 0;
      rx_count  <= 0;
    end else if (sw_rst_i) begin
      tx_wr_ptr <= 0;
      tx_rd_ptr <= 0;
      tx_count  <= 0;
      rx_wr_ptr <= 0;
      rx_rd_ptr <= 0;
      rx_count  <= 0;
    end else begin
      // TX Logic
      if (tx_fifo_push_i && tx_count < 16) begin
        tx_fifo[tx_wr_ptr] <= tx_fifo_data_i;
        tx_wr_ptr <= tx_wr_ptr + 1;
        tx_count <= tx_count + 1;  // Assuming no simultaneous pop
      end else if (tx_pop_enable && tx_count > 0) begin
        tx_rd_ptr <= tx_rd_ptr + 1;
        tx_count  <= tx_count - 1;
      end

      // RX Logic
      if (rx_push_enable && rx_count < 16) begin
        rx_fifo[rx_wr_ptr] <= rx_push_data;
        rx_wr_ptr <= rx_wr_ptr + 1;
        rx_count <= rx_count + 1;
      end else if (rx_fifo_pop_i && rx_count > 0) begin
        rx_rd_ptr <= rx_rd_ptr + 1;
        rx_count  <= rx_count - 1;
      end
    end
  end

  assign tx_elements_o   = tx_count[3:0];
  assign rx_elements_o   = rx_count[3:0];
  assign rx_fifo_data_o  = rx_fifo[rx_rd_ptr];
  assign rx_fifo_valid_o = (rx_count > 0);

  // --- Clock Divider ---
  logic [31:0] clk_cnt;
  logic        spi_clk_q;
  logic pulse_re, pulse_fe;  // Rising Edge, Falling Edge of virtual SPI clock

  logic cpol;
  logic [15:0] clk_div;

  assign cpol    = cfg_cpol_i;
  assign clk_div = {8'h00, cfg_clkdiv_i};

  // --- State Machine Declarations ---
  typedef enum logic [3:0] {
    IDLE,
    CMD,
    ADDR,
    DUMMY,
    DATA_TX,
    DATA_RX,
    PRE_FINISH,
    FINISH,
    WAIT_CS
  } state_t;

  state_t state_q, state_d;
  logic [31:0] bit_cnt_q, bit_cnt_d;
  logic [FIFO_DATA_WIDTH-1:0] shift_reg_q, shift_reg_d;
  logic [31:0] tx_word_cnt_q, tx_word_cnt_d;
  logic [31:0] rx_word_accum_q, rx_word_accum_d;

  // Trigger Latching
  logic trigger_tx_q, trigger_tx_d;
  logic trigger_rx_q, trigger_rx_d;

  logic clk_run;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      clk_cnt   <= 0;
      spi_clk_q <= 0;
    end else begin
      if (clk_run) begin
        if (clk_cnt >= clk_div) begin
          clk_cnt   <= 0;
          spi_clk_q <= ~spi_clk_q;
        end else begin
          clk_cnt <= clk_cnt + 1;
        end
      end else begin
        clk_cnt   <= 0;
        spi_clk_q <= 0;
      end
    end
  end

  // SPI Clock Output
  // Mode 0: CPOL=0. Idle 0. Run: 0->1->0... Output = spi_clk_q
  // Mode 3: CPOL=1. Idle 1. Run: 1->0->1... Output = ~spi_clk_q (if spi_clk_q toggles 0->1)
  // Actually, spi_clk_q starts 0. Toggles to 1.
  // If CPOL=1, we want Idle 1.
  // When Run: starts 1. Toggles to 0.
  // So spi_clk_o = spi_clk_q ^ cpol
  // Bypass Logic:
  // If bypass_i=1, use clk_i directly (gated by clk_run).
  // Note: clk_i is 0->1->0. 
  // If CPOL=0: Output = clk_run ? clk_i : 0.
  // If CPOL=1: Output = clk_run ? ~clk_i : 1.

  logic bypass_clk;
  assign bypass_clk = cpol ? ~clk_i : clk_i;

  assign spi_clk_o = cfg_clkdiv_bypass_i ? ((clk_run) ? bypass_clk : cpol) : 
                                           ((clk_run) ? (spi_clk_q ^ cpol) : cpol);

  // Pulses enable FSM transitions
  // We need pulses at edges of the *internal* base clock (spi_clk_q).
  // FSM logic assumes sampling/shifting on edges.
  // Mode 0: Sample Rising (0->1), Shift Falling (1->0).
  // Mode 3: Sample Rising (0->1), Shift Falling (1->0).
  // 
  // If spi_clk_o = spi_clk_q ^ cpol:
  // CPOL=0: spi_clk_o = spi_clk_q. Rising = (q=0->1). Falling = (q=1->0).
  // CPOL=1: spi_clk_o = ~spi_clk_q. Rising = (q=1->0). Falling = (q=0->1).
  //
  // Wait, if CPOL=1 (Idle 1):
  // Cycle starts. spi_clk_o goes 1->0 (Leading Edge). This is Falling.
  // Then 0->1 (Trailing Edge). This is Rising.
  //
  // In Mode 3, CPHA=1.
  // Data is sampled on the TRAILING edge (Rising).
  // Data is setup on the LEADING edge (Falling).
  //
  // In Mode 0, CPHA=0.
  // Data is sampled on the LEADING edge (Rising).
  // Data is setup on the TRAILING edge (Falling).
  //
  // So:
  // Mode 0: Sample on Leading (Rising). Setup on Trailing (Falling).
  // Mode 3: Sample on Trailing (Rising). Setup on Leading (Falling).
  //
  // The SPI Controller FSM logic currently:
  // Shift (Setup) on pulse_fe (Falling Edge).
  // Sample on pulse_re (Rising Edge).
  //
  // pulse_re = (cnt==div) && (q==0). Next q will be 1. So this is "About to go High" (Rising Edge).
  // pulse_fe = (cnt==div) && (q==1). Next q will be 0. So this is "About to go Low" (Falling Edge).
  //
  // If CPOL=0:
  // pulse_re is Rising Edge (Leading). Sample here.
  // pulse_fe is Falling Edge (Trailing). Setup here.
  // This matches Mode 0.
  //
  // If CPOL=1:
  // q transitions 0->1. But spi_clk_o = ~q, so 1->0. This is Falling Edge (Leading).
  // So pulse_re corresponds to output Falling Edge.
  // q transitions 1->0. spi_clk_o = ~q goes 0->1. This is Rising Edge (Trailing).
  // So pulse_fe corresponds to output Rising Edge.
  //
  // FSM Logic currently: 
  // Setup (Drive) on pulse_fe.
  // Sample (Capture) on pulse_re.
  //
  // If CPOL=1:
  // pulse_fe is Output Rising. 
  // pulse_re is Output Falling.
  //
  // Mode 3 requires:
  // Setup on Leading (Falling). -> This is pulse_re.
  // Sample on Trailing (Rising). -> This is pulse_fe.
  //
  // So if CPOL=1, we need to SWAP the pulses given to the FSM?
  //
  // Let's define:
  // internal_re = (cnt==div) && (q==0);
  // internal_fe = (cnt==div) && (q==1);
  //
  // if (cpol == 0) {
  //   pulse_re = internal_re; // Output Rising
  //   pulse_fe = internal_fe; // Output Falling
  // } else {
  //   pulse_re = internal_fe; // Output Rising (corresponds to q 1->0, so ~q 0->1)
  //   pulse_fe = internal_re; // Output Falling (corresponds to q 0->1, so ~q 1->0)
  // Pulses enable FSM transitions
  assign pulse_re  = cfg_clkdiv_bypass_i ? clk_run :
                     (cpol) ? ((clk_cnt == clk_div) && (spi_clk_q == 1)) : ((clk_cnt == clk_div) && (spi_clk_q == 0));
  assign pulse_fe  = cfg_clkdiv_bypass_i ? clk_run :
                     (cpol) ? ((clk_cnt == clk_div) && (spi_clk_q == 0)) : ((clk_cnt == clk_div) && (spi_clk_q == 1));

  // Mode 3 (CPOL=1, CPHA=1) Support:
  // In Mode 3, the first edge is Falling (Leading). The second is Rising (Trailing).
  // If we shift on the first Falling edge, we violate the setup time for the first bit (which should be valid at the first Rising edge).
  // Therefore, in Mode 3, we must SKIP shifting on the very first Falling edge of the transaction.
  // Subsequent Falling edges are valid shift points (setup for next rising edge).

  logic first_edge_q;
  logic pulse_fe_effective;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      first_edge_q <= 0;
    end else if (sw_rst_i || state_q == IDLE) begin
      first_edge_q <= 0;
    end else if (pulse_fe) begin
      first_edge_q <= 1;
    end
  end

  assign pulse_fe_effective = pulse_fe && (!cpol || first_edge_q);




  assign clk_run   = (state_q != IDLE && state_q != WAIT_CS && state_q != PRE_FINISH && state_q != FINISH);
  assign op_done_o = (state_q == WAIT_CS);

  always_comb begin
    state_d = state_q;
    bit_cnt_d = bit_cnt_q;
    shift_reg_d = shift_reg_q;
    tx_word_cnt_d = tx_word_cnt_q;
    rx_word_accum_d = rx_word_accum_q;
    trigger_tx_d = trigger_tx_q;
    trigger_rx_d = trigger_rx_q;

    tx_pop_enable = 0;
    rx_push_enable = 0;
    rx_push_data = 0;

    rx_push_data = 0;

    spi_csn_o = 4'b1111;  // Active Low, All Inactive by default
    if (state_q != IDLE && state_q != WAIT_CS && state_q != FINISH) begin
      spi_csn_o[cfg_cs_index_i] = 0;
    end

    spi_oe_o   = 0;
    spi_sdo_o  = 0;
    spi_mode_o = 0;

    case (state_q)
      IDLE: begin
        spi_csn_o = 4'b1111;
        tx_word_cnt_d = 0;
        trigger_tx_d = 0;  // Reset in IDLE by default? specific logic below
        trigger_rx_d = 0;

        if (trigger_tx_i || trigger_rx_i) begin
          state_d = CMD;
          bit_cnt_d = cfg_spilen_i[7:0];  // 8
          // Load CMD
          shift_reg_d = cfg_spicmd_i;
          trigger_tx_d = trigger_tx_i;
          trigger_rx_d = trigger_rx_i;
        end
      end

      CMD: begin
        spi_oe_o   = 4'b0001;
        spi_mode_o = 2'b00;  // Std
        // Drive MOSI with MSB
        if (bit_cnt_q > 0) spi_sdo_o[0] = shift_reg_q[bit_cnt_q-1];

        if (pulse_fe_effective) begin  // Falling Edge: Master drives new data
          if (bit_cnt_q == 1) begin
            // END CMD
            if (cfg_spilen_i[15:8] > 0) begin
              state_d = ADDR;
              bit_cnt_d = cfg_spilen_i[15:8];
              shift_reg_d = cfg_spiaddr_i;
            end else if (cfg_spidum_i > 0) begin
              state_d   = DUMMY;
              bit_cnt_d = cfg_spidum_i;
            end else if (cfg_spilen_i[31:16] > 0) begin
              if (trigger_tx_q) begin
                state_d = DATA_TX;
                bit_cnt_d = cfg_spilen_i[31:16];
                tx_word_cnt_d = 0;
                // Pop first word
                if (tx_count > 0) begin
                  shift_reg_d   = tx_fifo[tx_rd_ptr];
                  tx_pop_enable = 1;
                  tx_word_cnt_d = 32;
                end
              end else begin
                state_d = DATA_RX;
                bit_cnt_d = cfg_spilen_i[31:16];
                tx_word_cnt_d = 0;  // Usage reuse for rx accumulation count
              end
            end else begin
              state_d = PRE_FINISH;
            end
          end else begin
            bit_cnt_d = bit_cnt_q - 1;
          end
        end
      end

      ADDR: begin
        spi_oe_o   = 4'b0001;
        spi_mode_o = 2'b00;
        // Check if Quad Address?
        if (cfg_spicmd_i[31:30] == 2'b10) begin
          spi_mode_o = 2'b01;  // Quad Output
          spi_oe_o   = 4'b1111;
          if (bit_cnt_q >= 4) spi_sdo_o = shift_reg_q[bit_cnt_q-1-:4];

          if (pulse_fe_effective) begin
            if (bit_cnt_q <= 4) begin
              // Next
              if (cfg_spidum_i > 0) begin
                state_d   = DUMMY;
                bit_cnt_d = cfg_spidum_i;
              end else if (trigger_tx_q) begin
                state_d = DATA_TX;
                bit_cnt_d = cfg_spilen_i[31:16];
                tx_word_cnt_d = 0;
                if (tx_count > 0) begin
                  shift_reg_d   = tx_fifo[tx_rd_ptr];
                  tx_pop_enable = 1;
                  tx_word_cnt_d = 32;
                end
              end else begin
                state_d = DATA_RX;
                bit_cnt_d = cfg_spilen_i[31:16];
                tx_word_cnt_d = 0;
              end
            end else begin
              bit_cnt_d = bit_cnt_q - 4;
            end
          end
        end else begin
          // Std Addr
          if (bit_cnt_q > 0) spi_sdo_o[0] = shift_reg_q[bit_cnt_q-1];
          if (pulse_fe_effective) begin
            if (bit_cnt_q == 1) begin
              // Next
              if (cfg_spidum_i > 0) begin
                state_d   = DUMMY;
                bit_cnt_d = cfg_spidum_i;
              end else if (trigger_tx_q) begin
                state_d = DATA_TX;
                bit_cnt_d = cfg_spilen_i[31:16];
                tx_word_cnt_d = 0;
                if (tx_count > 0) begin
                  shift_reg_d   = tx_fifo[tx_rd_ptr];
                  tx_pop_enable = 1;
                  tx_word_cnt_d = 32;
                end else begin
                  tx_word_cnt_d = 0;
                end
              end else begin
                state_d = DATA_RX;
                bit_cnt_d = cfg_spilen_i[31:16];
                tx_word_cnt_d = 0;
              end
            end else begin
              bit_cnt_d = bit_cnt_q - 1;
            end
          end
        end
      end

      DUMMY: begin
        spi_oe_o = 0;
        // Wait for dummy cycles
        if (pulse_fe_effective) begin
          if (bit_cnt_q == 1) begin
            if (trigger_tx_q) begin
              state_d = DATA_TX;
              bit_cnt_d = cfg_spilen_i[31:16];
              tx_word_cnt_d = 0;
              if (tx_count > 0) begin
                shift_reg_d   = tx_fifo[tx_rd_ptr];
                tx_pop_enable = 1;
                tx_word_cnt_d = 32;
              end
            end else begin
              state_d = DATA_RX;
              bit_cnt_d = cfg_spilen_i[31:16];
              tx_word_cnt_d = 0;
            end
          end else begin
            bit_cnt_d = bit_cnt_q - 1;
          end
        end
      end

      DATA_TX: begin
        logic quad;
        quad = (cfg_spicmd_i[31:30] == 2'b10);

        if (quad) begin
          spi_mode_o = 2'b10;  // Quad Output (Note: TB uses mode 01 for both Dual/Quad TX? No, wait)
          // Reviewing TB: 
          // 00: Std
          // 01: Quad TX (All out) -> actually just "Multi-bit TX"
          // 10: Quad RX (All in)  -> actually just "Multi-bit RX"
          // Let's use 2'b01 for Dual TX as well, just drive 2 bits.

          spi_mode_o = 2'b01;
          spi_oe_o = 4'b1111;
          spi_sdo_o = shift_reg_q[31:28];

          if (pulse_fe_effective) begin
            shift_reg_d = {shift_reg_q[27:0], 4'b0};
            // Check Total Completion First
            if (bit_cnt_q <= 4) begin
              state_d = PRE_FINISH;
            end else begin
              // Continue
              bit_cnt_d = bit_cnt_q - 4;

              // Handle FIFO Refill
              if (tx_word_cnt_q <= 4) begin
                if (tx_count > 0) begin
                  shift_reg_d   = tx_fifo[tx_rd_ptr];
                  tx_pop_enable = 1;
                  tx_word_cnt_d = 32;
                end else tx_word_cnt_d = 0;
              end else begin
                tx_word_cnt_d = tx_word_cnt_q - 4;
              end
            end
          end
        end else if (cfg_spicmd_i[31:30] == 2'b01) begin  // Dual Mode
          spi_mode_o = 2'b01;  // Dual TX
          spi_oe_o = 4'b0011;  // Drive IO0, IO1
          spi_sdo_o[1:0] = shift_reg_q[31:30];  // MSB first on IO1, IO0? Or IO0, IO1? 
          // Standard Dual SPI (Dual Output): 
          // Even bits on IO0, Odd bits on IO1? Or MSB on IO1?
          // Usually: MSB (Bit 7) -> IO1, Bit 6 -> IO0.
          // Let's assume shift_reg[31] is MSB.
          // IO1 = Bit 31, IO0 = Bit 30.
          spi_sdo_o[1] = shift_reg_q[31];
          spi_sdo_o[0] = shift_reg_q[30];

          if (pulse_fe_effective) begin
            shift_reg_d = {shift_reg_q[29:0], 2'b0};
            // Check Total Completion First
            if (bit_cnt_q <= 2) begin
              state_d = PRE_FINISH;
            end else begin
              // Continue
              bit_cnt_d = bit_cnt_q - 2;

              // Handle FIFO Refill
              if (tx_word_cnt_q <= 2) begin
                if (tx_count > 0) begin
                  shift_reg_d   = tx_fifo[tx_rd_ptr];
                  tx_pop_enable = 1;
                  tx_word_cnt_d = 32;
                end else tx_word_cnt_d = 0;
              end else begin
                tx_word_cnt_d = tx_word_cnt_q - 2;
              end
            end
          end
        end else begin
          // Std
          spi_mode_o = 2'b00;
          spi_oe_o = 4'b0001;
          spi_sdo_o[0] = shift_reg_q[31];

          if (pulse_fe_effective) begin
            shift_reg_d = {shift_reg_q[30:0], 1'b0};
            // Check Total Completion First
            if (bit_cnt_q <= 1) begin
              state_d = PRE_FINISH;
            end else begin
              // Continue
              bit_cnt_d = bit_cnt_q - 1;

              // Handle FIFO Refill
              if (tx_word_cnt_q <= 1) begin
                if (tx_count > 0) begin
                  shift_reg_d   = tx_fifo[tx_rd_ptr];
                  tx_pop_enable = 1;
                  tx_word_cnt_d = 32;
                end else begin
                  tx_word_cnt_d = 0;
                end
              end else begin
                tx_word_cnt_d = tx_word_cnt_q - 1;
              end
            end
          end
        end
      end

      DATA_RX: begin
        logic quad;
        quad = (cfg_spicmd_i[31:30] == 2'b10);

        if (quad) begin
          spi_mode_o = 2'b10;  // Quad RX
          spi_oe_o   = 0;

          if (pulse_re) begin
            shift_reg_d = {shift_reg_q[FIFO_DATA_WIDTH-5:0], spi_sdi_i};
            // Accumulate
            if (tx_word_cnt_q >= FIFO_DATA_WIDTH - 4) begin
              rx_push_enable = 1;
              rx_push_data   = {shift_reg_q[FIFO_DATA_WIDTH-5:0], spi_sdi_i};
              tx_word_cnt_d  = 0;
            end else begin
              tx_word_cnt_d = tx_word_cnt_q + 4;
            end

            // Decrement
            if (bit_cnt_q >= 4) bit_cnt_d = bit_cnt_q - 4;
            else bit_cnt_d = 0;

            // Last Bit Push check
            if (bit_cnt_q <= 4) begin
              if (tx_word_cnt_d > 0) begin
                rx_push_enable = 1;
                rx_push_data   = shift_reg_d;
              end
            end
          end

          if (pulse_fe_effective) begin
            if (bit_cnt_d == 0) state_d = PRE_FINISH;
          end

        end else if (cfg_spicmd_i[31:30] == 2'b01) begin  // Dual Mode
          spi_mode_o = 2'b10;  // Dual RX (Mode 10 for RX)
          spi_oe_o   = 0;

          if (pulse_re) begin
            // Input: IO1 (Bit 1), IO0 (Bit 0).
            shift_reg_d = {shift_reg_q[FIFO_DATA_WIDTH-3:0], spi_sdi_i[1], spi_sdi_i[0]};

            if (tx_word_cnt_q >= FIFO_DATA_WIDTH - 2) begin
              rx_push_enable = 1;
              rx_push_data   = {shift_reg_q[FIFO_DATA_WIDTH-3:0], spi_sdi_i[1], spi_sdi_i[0]};
              tx_word_cnt_d  = 0;
            end else begin
              tx_word_cnt_d = tx_word_cnt_q + 2;
            end

            if (bit_cnt_q >= 2) bit_cnt_d = bit_cnt_q - 2;
            else bit_cnt_d = 0;

            if (bit_cnt_q <= 2) begin
              if (tx_word_cnt_d > 0) begin
                rx_push_enable = 1;
                rx_push_data   = shift_reg_d;
              end
            end
          end

          if (pulse_fe_effective) begin
            if (bit_cnt_d == 0) state_d = PRE_FINISH;
          end

        end else begin
          spi_mode_o = 2'b00;
          spi_oe_o   = 0;

          if (pulse_re) begin
            shift_reg_d = {
              shift_reg_q[FIFO_DATA_WIDTH-2:0], spi_sdi_i[1]
            };  // MISO is IO1 in Std Mode? 
            // Wait, standard SPI: MOSI=IO0, MISO=IO1.
            // Correct.
            $display("TIME=%t [CTRL] Sampled Bit: %b (SDI=%b) ShiftReg=%h", $time, spi_sdi_i[1],
                     spi_sdi_i, shift_reg_d);

            if (tx_word_cnt_q >= FIFO_DATA_WIDTH - 1) begin
              rx_push_enable = 1;
              rx_push_data   = {shift_reg_q[FIFO_DATA_WIDTH-2:0], spi_sdi_i[1]};
              tx_word_cnt_d  = 0;
            end else begin
              tx_word_cnt_d = tx_word_cnt_q + 1;
            end

            if (bit_cnt_q > 0) bit_cnt_d = bit_cnt_q - 1;

            if (bit_cnt_q == 1) begin
              if (tx_word_cnt_d > 0) begin
                rx_push_enable = 1;
                rx_push_data   = shift_reg_d;
              end
            end
          end

          if (pulse_fe_effective) begin
            if (bit_cnt_d == 0) state_d = PRE_FINISH;
          end
        end
      end

      PRE_FINISH: begin
        // Assert CS for the selected index
        // spi_csn_o[index] = 0. Others 1.
        // default is 1111.
        spi_csn_o[cfg_cs_index_i] = 0;
        state_d = FINISH;
      end

      FINISH: begin
        spi_csn_o = 4'b1111;

        // Partial Push if data remains
        // Logic handled in DATA_RX transition logic.

        state_d = WAIT_CS;
        trigger_tx_d = 0;
        trigger_rx_d = 0;
      end

      WAIT_CS: begin
        spi_csn_o = 4'b1111;
        if (!trigger_tx_q && !trigger_rx_q) state_d = IDLE;
      end
    endcase
  end

  // Trigger Latching FSM
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      state_q <= IDLE;
      bit_cnt_q <= 0;
      shift_reg_q <= 0;
      tx_word_cnt_q <= 0;
      rx_word_accum_q <= 0;
      trigger_tx_q <= 0;
      trigger_rx_q <= 0;
    end else if (sw_rst_i) begin
      state_q <= IDLE;
      trigger_tx_q <= 0;
      trigger_rx_q <= 0;
    end else begin
      state_q <= state_d;
      if (state_q != state_d)
        $display("[CTRL] State Change: %s -> %s. Time: %t", state_q.name(), state_d.name(), $time);
      bit_cnt_q <= bit_cnt_d;
      shift_reg_q <= shift_reg_d;
      tx_word_cnt_q <= tx_word_cnt_d;
      rx_word_accum_q <= rx_word_accum_d;
      trigger_tx_q <= trigger_tx_d;
      trigger_rx_q <= trigger_rx_d;
    end
  end

endmodule
