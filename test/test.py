import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles

@cocotb.test()
async def test_reset(dut):
    """Smoke test: the design comes out of reset and the QSPI clock toggles."""
    cocotb.start_soon(Clock(dut.clk, 40, units="ns").start())
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1
    # the core should start fetching: watch the QSPI clock line move
    seen = set()
    for _ in range(2000):
        await RisingEdge(dut.clk)
        seen.add(int(dut.uio_out.value) >> 4 & 1)
    assert 1 in seen and 0 in seen, "QSPI SCK never toggled; core not fetching"
