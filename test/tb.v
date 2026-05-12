`default_nettype none
`timescale 1ns/1ps

module tb;

    reg clk;
    reg rst_n;
    reg [7:0] ui_in;
    reg [7:0] uio_in;

    wire [7:0] uo_out;
    wire [7:0] uio_out;
    wire [7:0] uio_oe;

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

    always #10 clk = ~clk;

    initial begin
        clk = 0;
        rst_n = 0;
        ui_in = 0;
        uio_in = 0;

        #100;
        rst_n = 1;

        #200;
        ui_in[0] = 1;
        #2000;
        ui_in[0] = 0;

        #20000;

        $finish;
    end

endmodule
