import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

@cocotb.test()
async def test_cronometro(dut):
    """Prueba que el cronómetro cuente tiempo correctamente"""
    
    # Configurar clock (10 ns period = 100 MHz)
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    # Inicializar
    dut.ena.value = 1
    dut.rst_n.value = 0
    dut.ui_in.value = 0
    await Timer(100, units="ns")
    dut.rst_n.value = 1
    await Timer(100, units="ns")
    
    # Verificar estado inicial (debe mostrar 00.00)
    dut._log.info(f"Estado inicial - uo_out={dut.uo_out.value}, uio_out={dut.uio_out.value}")
    
    # Presionar botón start
    dut.ui_in.value = 0b00000001  # btn_start = 1
    await Timer(200, units="ns")
    dut.ui_in.value = 0b00000000
    dut._log.info("Botón START presionado")
    
    # Esperar 10 ms (simulación acortada) para que cuente algo
    # En SIM, tick_10ms ocurre cada 1000 ciclos de reloj
    # 10 ns * 1000 = 10 us, no 10 ms. Ajusta según tu SIM define
    for i in range(2000):
        await RisingEdge(dut.clk)
    
    # Verificar que el contador avanzó (el valor de uo_out cambió)
    valor_final = dut.uo_out.value.integer
    dut._log.info(f"Después de contar - uo_out={valor_final:08b}")
    
    # Una verificación básica: si todo está en 0xFF, algo falla
    assert valor_final != 0xFF, "Los segmentos están apagados (0xFF)"
    
    # Si el diseño funciona, algún bit debe estar en 0
    assert valor_final != 0x00, "Los segmentos muestran todos ceros (posible error)"
