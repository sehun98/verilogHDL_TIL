`timescale 1ns / 1ps

module FND_Controller (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [6:0] msec,
    input  wire [5:0] sec,
    input  wire [5:0] min,
    input  wire [4:0] hour,
    input  wire       time_unit_sel,
    output wire [3:0] digit,
    output wire [7:0] seg
);

    wire [7:0] seg_raw;

    wire [3:0] w_msec_ones;
    wire [3:0] w_msec_tens;
    wire [3:0] w_sec_ones;
    wire [3:0] w_sec_tens;
    wire [3:0] w_min_ones;
    wire [3:0] w_min_tens;
    wire [3:0] w_hour_ones;
    wire [3:0] w_hour_tens;

    wire [3:0] w_msec_sec_mux_out;
    wire [3:0] w_min_hour_mux_out;

    wire [1:0] w_digit_sel;

    wire [3:0] w_digit_out;

    assign seg = seg_raw;

    wire w_tick_1ms;

    digit_splitter #(
        .DATA_BIT(7)
    ) u1_msec_ds (
        .digit_data(msec),
        .digit_ones(w_msec_ones),
        .digit_tens(w_msec_tens)
    );

    digit_splitter #(
        .DATA_BIT(6)
    ) u2_sec_ds (
        .digit_data(sec),
        .digit_ones(w_sec_ones),
        .digit_tens(w_sec_tens)
    );

    digit_splitter #(
        .DATA_BIT(6)
    ) u3_min_ds (
        .digit_data(min),
        .digit_ones(w_min_ones),
        .digit_tens(w_min_tens)
    );

    digit_splitter #(
        .DATA_BIT(5)
    ) u4_hour_ds (
        .digit_data(hour),
        .digit_ones(w_hour_ones),
        .digit_tens(w_hour_tens)
    );

    mux_4to1 u5_mux_4to1_msec_sec (
        .digit_ones     (w_msec_ones),
        .digit_tens     (w_msec_tens),
        .digit_hundreds (w_sec_ones),
        .digit_thousands(w_sec_tens),
        .digit_sel      (w_digit_sel),
        .digit_out      (w_msec_sec_mux_out)
    );

    mux_4to1 u6_mux_4to1_min_hour (
        .digit_ones     (w_min_ones),
        .digit_tens     (w_min_tens),
        .digit_hundreds (w_hour_ones),
        .digit_thousands(w_hour_tens),
        .digit_sel      (w_digit_sel),
        .digit_out      (w_min_hour_mux_out)
    );

    mux2to1 u7_mux2to1 (
        .digit_ones(w_min_hour_mux_out),
        .digit_tens(w_msec_sec_mux_out),
        .digit_sel (time_unit_sel),
        .digit_out (w_digit_out)
    );

    BCD u8_BCD (
        .data_in(w_digit_out),
        .seg    (seg_raw)
    );

    tick_1ms u9_tick_1ms (
        .clk     (clk),
        .rst_n   (rst_n),
        .tick_1ms(w_tick_1ms)
    );

    counter_4 u10_counter_4 (
        .clk      (w_tick_1ms),
        .rst_n    (rst_n),
        .digit_sel(w_digit_sel)
    );

    decoder_2to4 u11_decoder_2to4 (
        .digit_sel(w_digit_sel),
        .digit    (digit)
    );
endmodule
