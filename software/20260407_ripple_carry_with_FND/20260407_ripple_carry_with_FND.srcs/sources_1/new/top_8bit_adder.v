`timescale 1ns / 1ps

module top_8bit_adder (
    input  wire       sysclk,
    input  wire       rst_n,
    input  wire [7:0] a,
    input  wire [7:0] b,
    output wire [7:0] seg,     // fnd_data
    output wire       c_out,   // led
    output wire [3:0] digit    //fnd_com
);

    wire [7:0] w_sum;
    wire [7:0] seg_raw;

    wire [3:0] w_digit_ones;
    wire [3:0] w_digit_tens;
    wire [3:0] w_digit_hundreds;
    wire [3:0] w_digit_thousands;

    wire [3:0] w_digit_out;

    wire [1:0] w_digit_sel;

    assign seg = seg_raw;

    wire tick;
    /*
        input wire [7:0] a,
        input wire [7:0] b,
        output wire [7:0] sum,
        output wire c_out
    */

    full_add_8bit u1_full_add_8bit (
        .a    (a),
        .b    (b),
        .sum  (w_sum),
        .c_out(c_out)
    );

    /*
        input  wire [7:0] sum_data,
        output wire [3:0] digit_ones,
        output wire [3:0] digit_tens,
        output wire [3:0] digit_hundreds,
        output wire [3:0] digit_thousands
    */

    digit_splitter u2_digit_splitter (
        .sum_data(w_sum),
        .digit_ones(w_digit_ones),
        .digit_tens(w_digit_tens),
        .digit_hundreds(w_digit_hundreds),
        .digit_thousands(w_digit_thousands)
    );

    /*
        input wire [3:0] digit_ones,
        input wire [3:0] digit_tens,
        input wire [3:0] digit_hundreds,
        input wire [3:0] digit_thousands,
        input wire [1:0] digit_sel,
        output reg [3:0] digit_out
    */

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
        .clk(sysclk),
        .rst_n(rst_n),
        .tick_1ms(tick)
    );
    
    counter_4 u7_counter_4 (
        .clk(tick),
        .rst_n(rst_n),
        .digit_sel(w_digit_sel)
    );

endmodule


