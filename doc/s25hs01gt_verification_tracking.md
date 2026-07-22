# S25HS01GT Vendor Model Verification Tracking

Tracks feature coverage for `axi_qspi_controller` against Infineon/Cypress's
real S25HS01GT behavioral model (`vendor/s25hs01gtRel/src/s25hs01gt.sv`),
via the dedicated testbench `tb/tb_axi_qspi_controller_s25hs01gt.sv`.

This is a *separate* coverage track from the repo's own simplified
`spi_flash_model.sv` and its regression in `tb/tb_axi_qspi_controller.sv` --
the real vendor model exercises real protocol quirks (JEDEC-standard
register maps, real power-up/erase/program timing, real Quad-Enable
requirements) that the simplified model doesn't model.

## Feature coverage

| Feature | Manual (register) | XIP (memory-mapped) |
|---|---|---|
| Standard Read (`0x03`) | PASS | PASS |
| Write (Page Program `0x02`) + read-back | PASS | PASS |
| Quad Output Read (`0x6B`) | PASS | PASS |
| Quad I/O Read + mode-byte (`0xEB`) | PASS | PASS |
| Dual Output Read (`0x3B`) | **N/A -- not implemented on this part, see below** | N/A |
| Dual I/O Read + mode-byte (`0xBB`) | PASS | PASS |
| 4-byte addressing (`EN4BA`/`0xB7`) | PASS | not tested |
| Sector Erase (`0x20`) | **FAIL -- known vendor model defect, see below** | n/a |
| Multi-beat AXI burst | n/a | PASS (structural: 4 beats, RLAST honored -- data content not meaningful, see note below) |
| Non-default CS (CS1/2/3) | not tested | not tested |
| Partial AXI write strobes | not tested | not tested |

Non-default CS and partial write strobes are controller-internal
AXI/CS-mux behaviors, not flash-model-specific -- already proven against
the repo's own simple model in `tb_axi_qspi_controller.sv` (Tests 14 and
16). Not planned for re-verification here unless a real reason to suspect
model-specific interaction shows up.

## Known issues

### Dual Output Read (`0x3B`) -- not a bug, genuinely unimplemented on this part

Tried first (same test shape as the other opcodes), failed with floating
(`0xFFFFFFFF`) data. Live trace showed the model's own `Instruct` never
left `NONE` and `bus_cycle_state` got stuck in the opcode-reception state
for the whole transaction -- the model never recognized `0x3B` as a valid
instruction at all. A text search of the entire 17,000-line model turns
up zero references to `0x3B` or "Dual Output" anywhere.

Confirmed via the real datasheet (`doc/002-12345_0X_V.pdf`, SFDP table):
`Dual Out instruction code = FFh` (the standard SFDP convention for "not
implemented"), while `Dual I/O instruction code = BBh` is listed and
supported. This is a genuine hardware limitation of this specific part --
S25HS01GT only implements the newer Dual *I/O* form (`0xBB`, address AND
data both dual, with a mode-byte phase like `0xEB`), not the legacy Dual
*Output* form (`0x3B`, address single-lane / data dual, no mode byte).
Not a defect in the controller, the vendor model, or the test -- the test
was simply asking for something this part was never wired to support.
`0xBB` is tested instead and passes (manual + XIP).

### Multi-beat AXI burst read -- structurally correct, content not meaningful

The burst-read check runs immediately after the (non-functional) Sector
Erase attempt, which leaves `STR1V`'s WIP bit stuck at `1` forever (see
below) -- the model may be silently ignoring subsequent commands while it
believes itself permanently busy, which would explain why the returned
burst data reads as `0xFFFFFFFF` for all 4 beats even at an address known
to hold real Page-Program content. The check only verifies burst
*mechanics* (`ARLEN`+1 beats returned, `RLAST` honored on the final beat),
which is unaffected by this and passes correctly. Re-run in isolation
(before Sector Erase, at a point where WIP is not stuck) if content
verification for bursts is needed.

### Sector Erase (`0x20`) never completes -- vendor model defect, not ours

Confirmed via a live hierarchical signal trace during an actual erase
attempt. `axi_qspi_controller`'s own protocol is clean throughout: correct
opcode, correct address, correct CS assert/deassert timing
(`bus_cycle_state` transitions `ADDRESS_BYTES -> STANDBY` exactly as
expected for an address-only command).

Root cause is inside `s25hs01gt.sv` itself: `ER004_C_0`'s (4KB Sector
Erase) real erase-trigger logic (the `ESTART` signal that starts the
model's own erase-completion timer) is nested inside a block gated on
`falling_edge_write` -- a signal that only pulses when a *data* phase
completes (edge-detected off `write`, which only gets cleared by
`data_cnt`-based logic for commands that have a data phase, e.g. Page
Program/WRAR). Sector Erase is opcode+address only, with no data phase --
`data_cnt` never advances for it, so `write` never clears, so
`falling_edge_write` structurally can never fire for a real erase
transaction. `STR1V` (status) and `ESTART` were confirmed to never change
from their pre-erase values for the entire duration of a bounded poll.

A real fix would require relocating `ER004_C_0`'s (and likely
`ER256_C_0`/`ERCHP_0_0`'s) case bodies into the model's *other* completion
path -- the one already used for other no-data commands like WREN, gated
on `rising_edge_CSNeg_ipd` instead of `falling_edge_write`. That's a
nontrivial structural change to a 17,000-line third-party file and has
not been attempted.

An earlier, narrower patch attempt assumed the bug was in the
`UniformSec` branch selection instead (mirroring the seemingly-correct
`Sec_Prot`/`ESTART` logic already present in the sibling `ER256_C_0`
case). That patch was reverted once a further trace showed the actual
execution path for this specific address doesn't even take that branch
(`UniformSec` was `0` for this device's power-on defaults) -- the real
defect is the `falling_edge_write` gating described above, not the
branch content.

**Two known local patches already applied to the downloaded model** (both
narrow, one-line-class fixes, documented at their point of use in
`s25hs01gt.sv`):
- `tdevice_CSRBL` specparam was used but never declared anywhere in the
  file (a real compile blocker) -- added at the same placeholder value
  (`1`) as every neighboring specparam in that block.
- (Sector Erase `UniformSec`-branch patch attempted and reverted -- see
  above; not a surviving local patch.)

### Test environment notes

- Real model timing requires waiting past `tdevice_PU` (450us power-up
  delay from simulation `t=0`, independent of reset) before any command
  will be processed -- confirmed the model logs `"Device is selected
  during Power Up"` and silently ignores commands issued before this.
- `CFR1V` (volatile Configuration Register 1, holds `QUADIT`/Quad-Enable
  at bit 1) must be written via `WRAR` (`0x71`) at register address
  `0x800002` (bit 23 set = volatile variant), preceded by the
  volatile-write-enable opcode `0x50` (sets an internal `WVREG` flag) --
  *not* standard `WREN` (`0x06`) at plain address `0x000002`, which
  targets the non-volatile `CFR1N` shadow instead and silently never
  completes.
- `TXFIFO` data is shifted out MSB-first for however many bits `SPILEN`'s
  data field specifies. For anything shorter than a full 32-bit transfer
  (e.g. `WRAR`'s single-byte register write), the value must be
  left-aligned into the top byte(s) of the 32-bit word, not right-aligned
  -- confirmed the hard way when a right-aligned `0x00000002` landed as
  `0x00` on the wire.

## History

- Two real, previously-undiscovered RTL bugs in `axi_qspi_controller.sv`/
  `spi_controller.sv` were found and fixed while bringing this model
  online (TXFIFO `swacc`/`.value` one-cycle timing bug; `trigger_tx_q`/
  `trigger_rx_q` latching bug that silently made every manual write
  execute as a read). Both are documented at their fix sites in
  `spi_controller.sv`/`axi_qspi_controller.sv` and independently verified
  via an isolated scratch testbench before being confirmed against this
  real vendor model.
