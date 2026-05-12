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

    # START (pulso suficiente para debounce)
    dut.ui_in.value = 1
    await ClockCycles(dut.clk, 2000)
    dut.ui_in.value = 0

    # Esperar que el contador avance
    await ClockCycles(dut.clk, 5000)

    val = dut.uo_out.value.integer
    dut._log.info(f"Output inicial: {val}")

    # Esperar más tiempo
    await ClockCycles(dut.clk, 5000)

    dut._log.info(f"Output final: {dut.uo_out.value.integer}")

    assert dut.uo_out.value.integer != val, "El cronómetro no avanzó"
