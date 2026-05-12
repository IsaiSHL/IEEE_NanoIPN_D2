/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_chronoINAAL (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);

    wire btn_start = ui_in[0];
    wire btn_lap   = ui_in[1];

    wire [7:0] segments;
    wire [3:0] anodes;

    cronometro_top uut (
        .clk(clk),
        .rst_n(rst_n),
        .btn_start(btn_start),
        .btn_lap(btn_lap),
        .segments(segments),
        .anodes(anodes)
    );

    assign uo_out = segments;

    assign uio_out[3:0] = anodes;
    assign uio_oe[3:0]  = 4'b1111;

    assign uio_out[7:4] = 4'b0000;
    assign uio_oe[7:4]  = 4'b0000;

    wire _unused = &{ena, ui_in[7:2], uio_in, 1'b0};

endmodule


module cronometro_top (
    input  wire clk,
    input  wire rst_n,
    input  wire btn_start,
    input  wire btn_lap,
    output wire [7:0] segments,
    output reg  [3:0] anodes
);

    wire start_pulse, lap_pulse;

    debounce db_start (
        .clk(clk),
        .rst_n(rst_n),
        .noisy_in(btn_start),
        .clean_pulse(start_pulse)
    );

    debounce db_lap (
        .clk(clk),
        .rst_n(rst_n),
        .noisy_in(btn_lap),
        .clean_pulse(lap_pulse)
    );

    wire tick_10ms;
    reg running;
    reg lap_mode;

    reg [3:0] cent_un, cent_dec;
    reg [3:0] seg_un, seg_dec;

    reg [19:0] prescaler_cnt;

`ifdef SIM
    assign tick_10ms = (prescaler_cnt == 1000);
`else
    assign tick_10ms = (prescaler_cnt == 20'd499999);
`endif

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            prescaler_cnt <= 0;
        else if (tick_10ms)
            prescaler_cnt <= 0;
        else
            prescaler_cnt <= prescaler_cnt + 1'b1;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            running  <= 0;
            lap_mode <= 0;
        end else begin
            if (start_pulse) running  <= ~running;
            if (lap_pulse)   lap_mode <= ~lap_mode;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cent_un  <= 0;
            cent_dec <= 0;
            seg_un   <= 0;
            seg_dec  <= 0;
        end else if (running && tick_10ms) begin
            if (cent_un == 9) begin
                cent_un <= 0;
                if (cent_dec == 9) begin
                    cent_dec <= 0;
                    if (seg_un == 9) begin
                        seg_un <= 0;
                        if (seg_dec == 5)
                            seg_dec <= 0;
                        else
                            seg_dec <= seg_dec + 1;
                    end else seg_un <= seg_un + 1;
                end else cent_dec <= cent_dec + 1;
            end else cent_un <= cent_un + 1;
        end
    end

    // =========================
    // DISPLAY REFRESH CORREGIDO
    // =========================

    reg [1:0] display_sel;
    reg [3:0] current_digit;
    reg [15:0] refresh_cnt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            refresh_cnt <= 0;
        else
            refresh_cnt <= refresh_cnt + 1;
    end

    wire refresh_tick = refresh_cnt[15];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            display_sel <= 0;
        else if (refresh_tick)
            display_sel <= display_sel + 1;
    end

    always @(*) begin
        case (display_sel)
            2'b00: begin
                current_digit = cent_un;
                anodes = 4'b1110;
            end
            2'b01: begin
                current_digit = cent_dec;
                anodes = 4'b1101;
            end
            2'b10: begin
                current_digit = seg_un;
                anodes = 4'b1011;
            end
            2'b11: begin
                current_digit = seg_dec;
                anodes = 4'b0111;
            end
            default: begin
                current_digit = 0;
                anodes = 4'b1111;
            end
        endcase
    end

    bcd_to_7seg decoder (
        .bcd(current_digit),
        .seg(segments)
    );

endmodule


module debounce (
    input  wire clk,
    input  wire rst_n,
    input  wire noisy_in,
    output reg  clean_pulse
);

    reg sync_0, sync_1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_0 <= 0;
            sync_1 <= 0;
        end else begin
            sync_0 <= noisy_in;
            sync_1 <= sync_0;
        end
    end

`ifdef SIM
    parameter MAX = 1000;
`else
    parameter MAX = 19'd499999;
`endif

    reg [18:0] cnt;
    reg stable_state;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt <= 0;
            stable_state <= 0;
        end else if (sync_1 != stable_state) begin
            cnt <= cnt + 1;
            if (cnt == MAX) begin
                stable_state <= sync_1;
                cnt <= 0;
            end
        end else begin
            cnt <= 0;
        end
    end

    reg stable_prev;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stable_prev <= 0;
            clean_pulse <= 0;
        end else begin
            clean_pulse <= (stable_state && !stable_prev);
            stable_prev <= stable_state;
        end
    end

endmodule


module bcd_to_7seg (
    input  wire [3:0] bcd,
    output reg  [7:0] seg
);
    always @(*) begin
        case (bcd)
            4'h0: seg = 8'b11000000;
            4'h1: seg = 8'b11111001;
            4'h2: seg = 8'b10100100;
            4'h3: seg = 8'b10110000;
            4'h4: seg = 8'b10011001;
            4'h5: seg = 8'b10010010;
            4'h6: seg = 8'b10000010;
            4'h7: seg = 8'b11111000;
            4'h8: seg = 8'b10000000;
            4'h9: seg = 8'b10010000;
            default: seg = 8'b11111111;
        endcase
    end
endmodule
