`timescale 1ns / 1ps

module top_ultrasonic (
    input wire clk,
    input wire rst_n,
    input wire start,
    output reg [7:0] seg
);
    wire [3:0] w_digit_out;
    wire [1:0] w_digit_sel;

    ultrasonic u1_ultrasonic (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .distance(distance),
        .trig(trig),
        .echo(echo)
    );

    digit_splitter u3_digit_splitter (
        .sum_data(sum_data),
        .digit_ones(digit_ones),
        .digit_tens(digit_tens),
        .digit_hundreds(digit_hundreds),
        .digit_thousands(digit_thousands)
    );

    decoder_2to4 u4_decoder_2to4 (
        .digit_sel(digit_sel),
        .digit(digit)
    );

    counter_4 u5_counter_4 (
        .clk(clk),
        .rst_n(rst_n),
        .digit_sel(w_digit_sel)
    );

    mux_4to1 u2_mux_4to1 (
        .digit_ones(digit_ones),
        .digit_tens(digit_tens),
        .digit_hundreds(digit_hundreds),
        .digit_thousands(digit_thousands),
        .digit_sel(w_digit_sel),
        .digit_out(w_digit_out)
    );

    BCD u6_BCD (
        .data_in(w_digit_out),
        .seg(seg)
    );

endmodule
