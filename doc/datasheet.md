# AXI QSPI Controller Datasheet

## 1. Overview
The AXI QSPI Controller is a bridge between an AXI4 Slave interface and a Quad-SPI (QSPI) interface. It supports both direct register-based SPI transactions and memory-mapped read access to SPI flash devices.

## 2. Parameters
| Parameter | Default | Description |
|-----------|---------|-------------|
| `AXI4_ADDRESS_WIDTH` | 32 | Width of the AXI4 address bus |
| `AXI4_RDATA_WIDTH` | 32 | Width of the AXI4 read data bus |
| `AXI4_WDATA_WIDTH` | 32 | Width of the AXI4 write data bus |
| `AXI4_ID_WIDTH` | 4 | Width of the AXI4 ID signals |
| `AXI4_USER_WIDTH` | 4 | Width of the AXI4 User signals |
| `BUFFER_DEPTH` | 16 | Depth of internal buffers (where applicable) |

## 3. Signal Description

### 3.1 Global Signals
| Signal | Direction | Description |
|--------|-----------|-------------|
| `s_axi_aclk` | Input | AXI Clock |
| `s_axi_aresetn` | Input | AXI Active-Low Reset |
| `fetch_en_i` | Input | Enable auto-initialization sequence after reset |
| `events_o` | Output | Event Status Flags (Reserved) |

### 3.2 AXI4 Slave Interface
Standard AXI4 Slave interface signals with configurable widths.

**Write Address Channel**
`s_axi_awvalid`, `s_axi_awid`, `s_axi_awlen`, `s_axi_awaddr`, `s_axi_awuser`, `s_axi_awready`

**Write Data Channel**
`s_axi_wvalid`, `s_axi_wdata`, `s_axi_wstrb`, `s_axi_wlast`, `s_axi_wuser`, `s_axi_wready`

**Write Response Channel**
`s_axi_bvalid`, `s_axi_bid`, `s_axi_bresp`, `s_axi_buser`, `s_axi_bready`

**Read Address Channel**
`s_axi_arvalid`, `s_axi_arid`, `s_axi_arlen`, `s_axi_araddr`, `s_axi_aruser`, `s_axi_arready`

**Read Data Channel**
`s_axi_rvalid`, `s_axi_rid`, `s_axi_rdata`, `s_axi_rresp`, `s_axi_rlast`, `s_axi_ruser`, `s_axi_rready`

### 3.3 SPI Interface
| Signal | Direction | Description |
|--------|-----------|-------------|
| `spi_clk` | Output | SPI Clock Output |
| `spi_csn0` - `spi_csn3` | Output | Chip Selects (Active Low) |
| `spi_mode` | Output | SPI Mode (Dual/Quad indicator, implementation specific) |
| `spi_sdo0` - `spi_sdo3` | Output | SPI Data Output (MOSI/IO) |
| `spi_sdi0` - `spi_sdi3` | Input | SPI Data Input (MISO/IO) |

## 4. Register Map
Base Address: `0x000` (Relative to AXI Base)

| Offset | Name | Description |
|--------|------|-------------|
| `0x00` | `STATUS` | Status and Control Register |
| `0x04` | `CLKDIV` | Clock Divider Configuration |
| `0x08` | `SPICMD` | SPI Command Register |
| `0x0C` | `SPIADR` | SPI Address Register |
| `0x10` | `SPILEN` | SPI Length Configuration |
| `0x14` | `SPIDUM` | SPI Dummy Cycles |
| `0x18` | `TXFIFO` | Transmit FIFO Data |
| `0x20` | `RXFIFO` | Receive FIFO Data |
| `0x24` | `CS_DEF` | Default Chip Select |
| `0x28` | `CS_A_0` | Chip Select 0 Base Address |
| `0x2C` | `CS_M_0` | Chip Select 0 Address Mask |
| `0x30` | `CS_A_1` | Chip Select 1 Base Address |
| `0x34` | `CS_M_1` | Chip Select 1 Address Mask |
| `0x38` | `CS_A_2` | Chip Select 2 Base Address |
| `0x3C` | `CS_M_2` | Chip Select 2 Address Mask |
| `0x40` | `CS_A_3` | Chip Select 3 Base Address |
| `0x44` | `CS_M_3` | Chip Select 3 Address Mask |

### Register Details

#### STATUS (0x00)
- `[4]` **sw_rst** (WO): Write 1 to trigger software reset.
- `[8]` **trig_rx** (WO): Write 1 to trigger RX operation.
- `[9]` **trig_tx** (WO): Write 1 to trigger TX operation.
- `[19:16]` **rx_cnt** (RO): RX FIFO element count.
- `[27:24]` **tx_cnt** (RO): TX FIFO element count.

#### CLKDIV (0x04)
- `[7:0]` **div** (RW): Clock Divider. `F_spi = F_axi / (2 * (div + 1))`. Default: 2.
- `[8]` **bypass** (RW): Bypass divider (1 = Bypass).
- `[31]` **cpol** (RW): Clock Polarity (0 = Mode 0, 1 = Mode 3).

#### SPICMD (0x08)
- `[31:0]` **cmd** (RW): Command to be sent.

#### SPIADR (0x0C)
- `[31:0]` **addr** (RW): Address to be sent.

#### SPILEN (0x10)
- `[7:0]` **cmd_len**: Length of Command field (in bits?).
- `[15:8]` **addr_len**: Length of Address field.
- `[31:16]` **data_len**: Length of Data field.

#### SPIDUM (0x14)
- `[31:0]` **dum** (RW): Dummy cycles configuration.

#### TXFIFO (0x18)
- `[31:0]` **data** (WO): Write data to TX FIFO.

#### RXFIFO (0x20)
- `[31:0]` **data** (RO): Read data from RX FIFO.

## 5. Functional Description

### 5.1 Operating Modes
1.  **Register Access Mode** (Address < 0x1000):
    -   Used for configuration and manual SPI transactions.
    -   Accesses the register map directly.
2.  **Memory Mapped Mode** (Address >= 0x1000):
    -   Directly maps AXI Read transactions to SPI Flash reads.
    -   The controller automatically issues a standard Read command (0x03) to the flash.
    -   Supports eXecute In Place (XIP).

### 5.2 Auto-Initialization
If `fetch_en_i` is high at reset, the controller enters an auto-initialization sequence:
1.  Reset Enable (0x66)
2.  Reset (0x99)
3.  Write Enable (0x06)
4.  Write Status Register (0x01) with Quad Enable bit (0x40).

## 6. Programming Guide

### 6.1 SPI Clock Configuration
Set the SPI clock frequency using the `CLKDIV` register.
```c
// Example: Set divisor to 4
write_reg(CLKDIV, 0x04);
```

### 6.2 Manual Transaction
To perform a manual SPI transaction (e.g., Reading JEDEC ID):
1.  **Configure Lengths**: Set command, address, and data lengths in `SPILEN`.
2.  **Set Command**: Write the opcode to `SPICMD`.
3.  **Set Address** (if applicable): Write to `SPIADR`.
4.  **Fill TX FIFO** (if writing): Write data to `TXFIFO`.
5.  **Trigger**: Write 1 to `trig_tx` (for write) or `trig_rx` (for read) in `STATUS`.
6.  **Wait**: Poll `STATUS` or wait for completion.
7.  **Read RX FIFO**: Read data from `RXFIFO`.

### 6.3 Memory Mapped Configuration
To enable memory mapped access for specific Chip Selects:
1.  **Configure Masks**: Set `CS_M_x` registers to mask the AXI address bits.
2.  **Configure Base**: Set `CS_A_x` registers to match the base address for that CS.
3.  **Default CS**: Set `CS_DEF` for accesses that don't match any mask.

Example:
Map CS0 to AXI Address `0x1000_0000`:
- `CS_M_0` = `0xFF00_0000`
- `CS_A_0` = `0x1000_0000`
Accessing `0x1000_0004` will activate CS0 and send address `0x000004` to the flash (plus internal offset subtraction).

Note: The internal logic subtracts `0x1000` from the AXI address before sending to the SPI controller in Memory Mapped mode.
