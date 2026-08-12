## How it works

This is the **Tile A** right-sized build of ASICirific: a single-issue RV32I
microcontroller you can program over USB-C, like an ESP32.

- **Core:** a six-stage RISC-V pipeline (RV32I; the M extension is compiled out
  to save area) with forwarding, hazard interlocks, and a gshare + BTB + RAS
  branch predictor.
- **Memory:** a small on-chip SRAM that holds your program.
- **Serial bootloader:** while `BOOT` (ui[1]) is high at reset, the core is held
  in reset and an on-die loader listens on the UART for a program, writes it into
  SRAM, checks a checksum, and releases the core to run it. This is the
  ESP32-classic "program over USB" path: a USB-to-UART bridge on your board turns
  USB-C into the serial stream this loader speaks.
- **Peripherals:** UART, 8 bits of GPIO, and a JTAG debug port (a RISC-V Debug
  Module) so OpenOCD can halt the core and peek/poke SRAM.

The full ASICirific (six-stage RV32IM, an AES secure enclave, a matrix
homomorphic-encryption engine, and ADC/DAC/TRNG key generation) is a larger,
multi-tile design in the sibling `asicirific/` project.

## How to test

Bring `BOOT` (ui[1]) high, hold reset, then release. `boot_active` (uo[1]) goes
high to show download mode. Send a framed program over the UART at the tile
clock's baud:

```
b"ASIC" + count(4, LE) + words(4*count, LE) + checksum(4, LE)
```

The loader replies with `0x9D` (loaded OK) or `0xEE` (checksum error) and, on
success, drops `boot_active` and runs your program. The included cocotb test
flashes a four-instruction program that writes `0xAB` to the GPIO and confirms
the output pins show it. On a board, `scripts/flash.py` in the sibling project
does this over a real serial port with DTR/RTS auto-reset.

## External hardware

- A USB-to-UART bridge (CP2102N, CH340, or FT231X) for the USB-C programming
  path: bridge TXD -> ui[0], RXD <- uo[0], DTR -> BOOT (ui[1]), RTS -> reset.
- Optionally a JTAG adapter on uio[0:3] for OpenOCD debug.
- LEDs on the GPIO outputs (uo[3:7], uio[4:6]) to see your program run.
