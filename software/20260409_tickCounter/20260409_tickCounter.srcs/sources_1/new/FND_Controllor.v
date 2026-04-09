`timescale 1ns / 1ps

module FND_Controllor(
    input wire clk,
    input wire rst_n,
    input wire [13:0] data,
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

    wire w_tick;


    digit_splitter u2_digit_splitter (
        .sum_data(data),
        .digit_ones(w_digit_ones),
        .digit_tens(w_digit_tens),
        .digit_hundreds(w_digit_hundreds),
        .digit_thousands(w_digit_thousands)
    );

    mux_4x1 u3_mux_4x1 (
        .digit_ones(w_digit_ones),
        .digit_tens(w_digit_tens),
        .digit_hundreds(w_digit_hundreds),
        .digit_thousands(w_digit_thousands),
        .digit_sel(w_digit_sel),
        .digit_out(w_digit_out)
    );

    BCD u4_BCD (
        .data_in(w_digit_out),
        .seg    (seg_raw)
    );

    decoder_2x4 u5_decoder_2x4 (
        .digit_sel(w_digit_sel),
        .digit(digit)
    );

    tick_generator u6_tick_generator (
        .clk(clk),
        .rst_n(rst_n),
        .tick_1ms(w_tick)
    );
    
    counter_4 u7_counter_4 (
        .clk(w_tick),
        .rst_n(rst_n),
        .digit_sel(w_digit_sel)
    );

endmodule