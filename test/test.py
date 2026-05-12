from cocotb.triggers import Timer
from cocotb.clock import Clock
import cocotb

@cocotb.test()
async def test_cronometro(dut):

    # Clock
    clock = Clock(dut.clk, 10, unit="ns")
    cocotb.start_soon(clock.start())

    # Reset correcto
    dut.rst_n.value = 0
    dut.ena.value = 1
    dut.ui_in.value = 0

    await Timer(100, unit="ns")

    dut.rst_n.value = 1  # liberar reset

    await Timer(100, unit="ns")

    dut._log.info("Reset complete")
