`timescale 1ns / 1ps

module FND_Controller(
    input wire clk,
    input wire rst_n,
    input wire [9:0] data,
    output wire [3:0] digit,
    output wire [7:0] seg
    );

    wire [7:0] seg_raw;

    wire [3:0] w_digit_ones;
    wire [3:0] w_digit_tens;
    wire [3:0] w_digit_hundreds;
    wire [3:0] w_digit_thousands;

    wire [3:0] w_digit_out;

    wire [1:0] w_digit_sel;

    assign seg = seg_raw;

    wire w_square_wave_1ms_toggle;

    digit_splitter u1_digit_splitter (
        .sum_data(data),
        .digit_ones(w_digit_ones),
        .digit_tens(w_digit_tens),
        .digit_hundreds(w_digit_hundreds),
        .digit_thousands(w_digit_thousands)
    );

    mux_4to1 u2_mux_4to1 (
        .digit_ones(w_digit_ones),
        .digit_tens(w_digit_tens),
        .digit_hundreds(w_digit_hundreds),
        .digit_thousands(w_digit_thousands),
        .digit_sel(w_digit_sel),
        .digit_out(w_digit_out)
    );

    BCD u3_BCD (
        .data_in(w_digit_out),
        .seg    (seg_raw)
    );

    square_wave_generator u4_square_wave_generator (
        .clk(clk),
        .rst_n(rst_n),
        .square_wave_1ms_toggle(w_square_wave_1ms_toggle)
    );

    counter_4 u5_counter_4 (
        .clk(w_square_wave_1ms_toggle),
        .rst_n(rst_n),
        .digit_sel(w_digit_sel)
    );

    decoder_2to4 u6_decoder_2to4 (
        .digit_sel(w_digit_sel),
        .digit(digit)
    );
endmodule