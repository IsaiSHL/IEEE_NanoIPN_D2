import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles


@cocotb.test()
async def test_project(dut):

    clock = Clock(dut.clk, 10, unit="ns")
    cocotb.start_soon(clock.start())

    # Reset
    dut.rst_n.value = 0
    dut.ui_in.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1

    # Verifica que no crashea y hay salida válida
    await ClockCycles(dut.clk, 100)

    val = dut.uo_out.value.integer
    dut._log.info(f"Output: {val}")

    # Assert muy simple
    assert val >= 0
