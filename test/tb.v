`default_nettype none

`timescale 1ns/1ps

module tb;

    // Señales del DUT
    reg clk;
    reg rst_n;
    reg [7:0] ui_in;
    reg [7:0] uio_in;

    wire [7:0] uo_out;
    wire [7:0] uio_out;
    wire [7:0] uio_oe;

    // Instancia del diseño (wrapper)
    tt_um_chronoINAAL dut (
        .ui_in(ui_in),
        .uo_out(uo_out),
        .uio_in(uio_in),
        .uio_out(uio_out),
        .uio_oe(uio_oe),
        .ena(1'b1),
        .clk(clk),
        .rst_n(rst_n)
    );

    // -----------------------
    // Clock (50MHz → 20ns)
    // -----------------------
    always #10 clk = ~clk;

    // -----------------------
    // Simulación
    // -----------------------
    initial begin
        // Inicialización
        clk = 0;
        rst_n = 0;
        ui_in = 0;
        uio_in = 0;

        // Reset
        #100;
        rst_n = 1;

        // -----------------------
        // START (simula rebote leve)
        // -----------------------
        #200;
        ui_in[0] = 1;
        #20;
        ui_in[0] = 0;

        // Dejar correr tiempo
        #100000;

        // -----------------------
        // LAP
        // -----------------------
        ui_in[1] = 1;
        #20;
        ui_in[1] = 0;

        #50000;

        // -----------------------
        // STOP
        // -----------------------
        ui_in[0] = 1;
        #20;
        ui_in[0] = 0;

        #50000;

        $finish;
    end

    // -----------------------
    // Monitor (debug útil)
    // -----------------------
    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, tb);

        $display("Time\tSegments\tAnodes");
        $monitor("%0t\t%b\t%b", $time, uo_out, uio_out[3:0]);
    end

endmodule
