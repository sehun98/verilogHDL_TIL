`timescale 1ns / 1ps

module FND_controller (
    input wire clk,
    input wire rst_n,
    input wire [13:0] data,
    output wire [3:0] digit,
    output wire [7:0] fnd_decode
);

    parameter CLOCK_FREQ_HZ = 100_000_000;
    parameter HZ = 1000;
    parameter N = 4;

    wire [3:0] w_digit_1;
    wire [3:0] w_digit_10;
    wire [3:0] w_digit_100;
    wire [3:0] w_digit_1000;

    wire [3:0] w_digit_out;

    wire w_tick;

    wire [$clog2(N)-1:0] w_digit_sel;

    digit_splitter_4 u1_digit_splitter_4 (
        .i_data      (data),
        .o_digit_1   (w_digit_1),
        .o_digit_10  (w_digit_10),
        .o_digit_100 (w_digit_100),
        .o_digit_1000(w_digit_1000)
    );

    mux4to1 u2_mux4to1 (
        .i_digit_sel (w_digit_sel),
        .i_digit_1   (w_digit_1),
        .i_digit_10  (w_digit_10),
        .i_digit_100 (w_digit_100),
        .i_digit_1000(w_digit_1000),
        .o_digit_out (w_digit_out)
    );

    BCD u3_BCD (
        .i_data(w_digit_out),
        .o_fnd_decode(fnd_decode)
    );

    tick_gen_1000hz #(
        .CLOCK_FREQ_HZ(CLOCK_FREQ_HZ),
        .HZ(HZ)
    ) u4_tick_gen_1000hz (
        .clk  (clk),
        .rst_n(rst_n),
        .tick (w_tick)
    );

    count #(
        .N(N)
    ) u5_count (
        .clk  (clk),
        .rst_n(rst_n),
        .tick (w_tick),
        .count(w_digit_sel)
    );

    decode2to4 u6_decode2to4 (
        .count(w_digit_sel),
        .digit(digit)
    );

endmodule
