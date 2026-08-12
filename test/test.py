# test.py — cocotb test for the ASICirific TinyTapeout subset.
#
# Acts as the USB-UART host: holds BOOT high, sends a tiny RV32I program over
# the serial line at the bootloader's baud, and confirms the loader wrote it,
# released the core, and the core executed it (GPIO shows the programmed value).
# This is the same end-to-end proof as the Verilator bootloader test, in the
# TinyTapeout-standard cocotb form.

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles

# must match main_soc BOOT_DIV (clocks per UART bit)
DIV = 217

# a small RV32I program: gpio_out = 0xAB, then spin
#   addi x5,x0,0xAB ; lui x6,0x20001 ; sw x5,0(x6) ; j .
PROG = [0x0AB00293, 0x20001337, 0x00532023, 0x0000006F]


async def send_bit(dut, b):
    dut.ui_in.value = (int(dut.ui_in.value) & ~0x1) | (b & 1)  # ui_in[0] = uart_rx
    await ClockCycles(dut.clk, DIV)


async def send_byte(dut, val):
    await send_bit(dut, 0)                 # start bit
    for i in range(8):
        await send_bit(dut, (val >> i) & 1)  # LSB first
    await send_bit(dut, 1)                 # stop bit
    await ClockCycles(dut.clk, DIV // 2)   # inter-byte gap


async def send_word(dut, w):
    for i in range(4):
        await send_byte(dut, (w >> (8 * i)) & 0xFF)


@cocotb.test()
async def test_usb_bootloader(dut):
    """Flash a program over UART and confirm the core runs it."""
    dut._log.info("start")
    cocotb.start_soon(Clock(dut.clk, 40, units="ns").start())  # 25 MHz

    # BOOT high (ui_in[1]) so we enter download mode; serial idle high (ui_in[0]=1)
    dut.ena.value   = 1
    dut.ui_in.value = 0b0000_0011          # ui_in[1]=BOOT=1, ui_in[0]=uart_rx idle high
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 5)

    # uo_out[1] = boot_active should be high in download mode
    assert (int(dut.uo_out.value) >> 1) & 1 == 1, "not in download mode"

    checksum = sum(PROG) & 0xFFFFFFFF
    for c in b"ASIC":
        await send_byte(dut, c)
    await send_word(dut, len(PROG))
    for w in PROG:
        await send_word(dut, w)
    await send_word(dut, checksum)

    # wait for the loader to release the core (boot_active -> 0)
    for _ in range(20000):
        await RisingEdge(dut.clk)
        if (int(dut.uo_out.value) >> 1) & 1 == 0:
            break
    assert (int(dut.uo_out.value) >> 1) & 1 == 0, "loader never released the core"

    # core runs from SRAM; gpio_out[4:0] appear on uo_out[7:3].
    # 0xAB & 0x1F = 0x0B -> expect uo_out[7:3] == 0b01011
    target = 0xAB & 0x1F
    got = 0
    for _ in range(4000):
        await RisingEdge(dut.clk)
        got = (int(dut.uo_out.value) >> 3) & 0x1F
        if got == target:
            break
    assert got == target, f"core did not run loaded program: uo_out[7:3]=0x{got:02x} want 0x{target:02x}"

    dut._log.info(f"PASS: flashed {len(PROG)} words, core ran it, gpio low bits = 0x{got:02x}")
