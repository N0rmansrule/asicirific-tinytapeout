## How it works

ASICirific is a bit-serial RV32E microcontroller. The whole computer sits in a
few TinyTapeout tiles by keeping the datapath one bit wide and putting all memory
on external QSPI chips.

- **CPU**: a bit-serial RV32E core. Instructions are fetched as whole words and
  decoded in parallel, but operands stream one bit per clock from a shift-register
  file through a one-bit ALU and back. This is what makes it small. Most
  instructions take a couple of 32-cycle passes.
- **Memory**: a QSPI controller drives an external NOR flash for the program and
  an external PSRAM for data, sharing one 4-wire bus. There is no on-chip RAM.
- **I/O**: a GPIO block. Inputs read buttons, outputs drive LEDs and sensor lines.
  Serial, SPI, and I2C are bit-banged in software over GPIO.

Address map: `0x0000_0000` flash (program), `0x0100_0000` PSRAM (data),
`0x0200_0000` GPIO (OUT at +0x00, IN at +0x04, OE at +0x08).

## How to test

Program the external flash over USB-C using the demo board's RP2040, then reset.
The CPU runs from flash. A first program can read a button on `ui_in` and drive an
LED on `uo_out`. Data variables live in the PSRAM.

## External hardware

- QSPI NOR flash for the program, e.g. Winbond W25Q128JVSIM (16 MB).
- QSPI PSRAM for data, e.g. AP Memory APS6404L-3SQR-SN (8 MB).
- Or the ready-made TinyTapeout QSPI Pmod, which carries both.
- Buttons on the `ui_in` pins, LEDs or sensors on `uo_out`.

## Implementation results

Hardened for sky130A on 3x2 tiles (508.76 x 225.76 um), no macros, no on-chip RAM.

| Metric | Value |
|---|---|
| Target clock | 25 MHz (40 ns) |
| Setup slack, slow corner (ss 100C 1.60V) | +17.09 ns |
| Setup slack, typical | +24.34 ns |
| Hold slack, worst (ff -40C 1.95V) | +0.098 ns |
| Clock skew | 0.27 ns |
| Total power, typical | 1.72 mW |
| Cell utilization | 59.6% |

Timing closes with wide margin at 25 MHz; the slow corner suggests roughly
40 MHz is achievable. DRC, LVS, and antenna checks all pass.

## Implementation results

Hardened for sky130A on 3x2 tiles (508.76 x 225.76 um), no macros, no on-chip RAM.

| Metric | Value |
|---|---|
| Target clock | 25 MHz (40 ns) |
| Setup slack, slow corner (ss 100C 1.60V) | +17.09 ns |
| Setup slack, typical | +24.34 ns |
| Hold slack, worst (ff -40C 1.95V) | +0.098 ns |
| Clock skew | 0.27 ns |
| Total power, typical | 1.72 mW |
| Cell utilization | 59.6% |

Timing closes with wide margin at 25 MHz; the slow corner suggests roughly
40 MHz is achievable. DRC, LVS, and antenna checks all pass. Verified with an
independent local harden as well as CI.
