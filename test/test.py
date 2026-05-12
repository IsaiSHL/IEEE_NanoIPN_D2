@cocotb.test()
async def test_project(dut):

    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    # Reset
    dut.rst_n.value = 0
    dut.ui_in.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1

    # START
    dut.ui_in.value = 1
    await ClockCycles(dut.clk, 2)
    dut.ui_in.value = 0

    # Esperar que el cronómetro avance
    await ClockCycles(dut.clk, 50)

    dut._log.info(f"Output: {dut.uo_out.value}")

    # Verifica que algo cambió
    assert dut.uo_out.value.integer != 0
