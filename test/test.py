import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

@cocotb.test()
async def test_cronometro(dut):
    """Prueba completa del cronómetro"""
    
    # Generar reloj de 100 MHz (periodo 10 ns)
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    # === Inicialización ===
    dut.ena.value = 1      # IMPORTANTE: Habilitar el chip
    dut.rst_n.value = 0    # Reset activo
    dut.ui_in.value = 0    # Todos los botones en 0
    await Timer(100, units="ns")
    
    # Liberar reset
    dut.rst_n.value = 1
    await Timer(100, units="ns")
    
    dut._log.info("=== Inicialización completa ===")
    dut._log.info(f"uo_out inicial = {dut.uo_out.value.binstr}")
    
    # === Prueba 1: Presionar botón START ===
    dut._log.info("Presionando botón START...")
    dut.ui_in.value = 0b00000001  # btn_start = 1
    await Timer(200, units="ns")   # Mantener presionado
    dut.ui_in.value = 0b00000000  # Soltar botón
    
    # Esperar varios ciclos para que el cronómetro cuente
    # En SIM, tick_10ms ocurre cada 1000 ciclos (10 us a 100 MHz)
    await Timer(20000, units="ns")  # 20 microsegundos
    
    valor1 = dut.uo_out.value.integer
    dut._log.info(f"uo_out después de START = {valor1:08b}")
    
    # === Prueba 2: Verificar que cambió ===
    # Si el cronómetro funciona, debe mostrar algo diferente a 0xFF
    assert valor1 != 0xFF, "FAIL: Los segmentos están apagados (todo en 1)"
    
    # === Prueba 3: Presionar LAP (opcional) ===
    dut._log.info("Presionando botón LAP...")
    dut.ui_in.value = 0b00000010  # btn_lap = 1
    await Timer(200, units="ns")
    dut.ui_in.value = 0b00000000
    
    await Timer(10000, units="ns")
    valor2 = dut.uo_out.value.integer
    dut._log.info(f"uo_out después de LAP = {valor2:08b}")
    
    # === Verificación final ===
    assert valor2 != 0xFF, "FAIL: Los segmentos se apagaron después de LAP"
    dut._log.info("=== TODAS LAS PRUEBAS PASARON ===")
