`timescale 1ns / 1ps

module FND_Controller (
    input wire       clk,
    input wire       rst_n,
    input wire [6:0] msec,
    input wire [5:0] sec,
    input wire [5:0] min,
    input wire [4:0] hour,
    input wire       time_unit_sel,
    input wire       set_mode_sw,
    input wire       stopwatch_watch_sw,
    input wire       ultra_temp_sel_sw,
    input wire       watch_sensor_sw,

    input wire [8:0] distance,
    input wire [7:0] humidity,
    input wire [7:0] temperature,

    input  wire [2:0] dot_sel,
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

    
    wire [3:0] w_humid_ones;
    wire [3:0] w_humid_tens;
    wire [3:0] w_temp_tens;
    wire [3:0] w_temp_ones;

    wire [3:0] w_msec_sec_mux_out;
    wire [3:0] w_min_hour_mux_out;

    wire [2:0] w_digit_sel;

    wire [3:0] w_digit_out;

    assign seg = seg_raw;

    wire w_tick_1ms;

    wire w_hit;

    wire [3:0] w_digit_0;
    wire [3:0] w_digit_1;
    wire [3:0] w_digit_2;
    wire [3:0] w_digit_3;
    wire [3:0] w_digit_4;
    wire [3:0] w_digit_5;
    wire [3:0] w_digit_6;
    wire [3:0] w_digit_7;


    wire [3:0] w_time_digit_out;
    wire [3:0] w_temp_ultra_digit_out;

    wire [3:0] w_temp_humid_mux_out;
    wire [3:0] w_distance_mux_out;
    wire [3:0] w_distance_ones;
    wire [3:0] w_distance_tens;
    wire [3:0] w_distance_hundereds;
    wire [3:0] w_distance_thousands;
    
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

    digit_splitter #(
        .DATA_BIT(8)
    ) u5_temp_ds (
        .digit_data(temperature),
        .digit_ones(w_temp_ones),
        .digit_tens(w_temp_tens)
    );

    digit_splitter #(
        .DATA_BIT(8)
    ) u6_humid_ds (
        .digit_data(humidity),
        .digit_ones(w_humid_ones),
        .digit_tens(w_humid_tens)
    );

    digit_splitter_1to4 #(
        .DATA_BIT(9)
    ) u7_distance_ds (
        .digit_data     (distance),
        .digit_ones     (w_distance_ones),
        .digit_tens     (w_distance_tens),
        .digit_hundreds (w_distance_hundereds),
        .digit_thousands(w_distance_thousands)
    );

    mux_4to1 u14_mux_4to1_temp_humid (
        .digit_1(w_humid_ones),
        .digit_2(w_humid_tens),
        .digit_3(w_temp_ones),
        .digit_4(w_temp_tens),

        .digit_sel(w_digit_sel),  //
        .digit_out(w_temp_humid_mux_out)  // 
    );

    mux_4to1 u14_mux_4to1_ultra (
        .digit_1(w_distance_ones),
        .digit_2(w_distance_tens),
        .digit_3(w_distance_hundereds),
        .digit_4(w_distance_thousands),

        .digit_sel(w_digit_sel),  //
        .digit_out(w_distance_mux_out)
    );

    mux_8to1 u5_mux_8to1_min_hour (
        .digit_1(w_min_ones),
        .digit_2(w_min_tens),
        .digit_3(w_hour_ones),
        .digit_4(w_hour_tens),

        .digit_5(w_digit_4),
        .digit_6(w_digit_5),
        .digit_7(w_digit_6),
        .digit_8(w_digit_7),

        .digit_sel(w_digit_sel),
        .digit_out(w_min_hour_mux_out)
    );

    mux_8to1 u6_mux_8to1_msec_sec (
        .digit_1(w_msec_ones),
        .digit_2(w_msec_tens),
        .digit_3(w_sec_ones),
        .digit_4(w_sec_tens),

        .digit_5(w_digit_0),
        .digit_6(w_digit_1),
        .digit_7(w_digit_2),
        .digit_8(w_digit_3),

        .digit_sel(w_digit_sel),
        .digit_out(w_msec_sec_mux_out)
    );

    comparator u7_comparator (
        .clk  (clk),
        .rst_n(rst_n),
        .tick (w_tick_1ms),
        .hit  (w_hit)
    );

    demux_1to8 u8_demux_1to8 (
        .hit      (w_hit),
        .digit_sel(dot_sel),

        .set_mode_sw(set_mode_sw),
        .stopwatch_watch_sw(stopwatch_watch_sw),

        .digit_0(w_digit_7),
        .digit_1(w_digit_6),
        .digit_2(w_digit_5),
        .digit_3(w_digit_4),
        .digit_4(w_digit_3),
        .digit_5(w_digit_2),
        .digit_6(w_digit_1),
        .digit_7(w_digit_0)
    );

    mux_2to1 u9_mux_2to1 (
        .digit_ones(w_min_hour_mux_out),
        .digit_tens(w_msec_sec_mux_out),
        .digit_sel (time_unit_sel),
        .digit_out (w_time_digit_out)
    );

    mux_2to1 u10_mux_2to1 (
        .digit_ones(w_temp_humid_mux_out),
        .digit_tens(w_distance_mux_out),
        .digit_sel (ultra_temp_sel_sw),
        .digit_out (w_temp_ultra_digit_out)
    );

    mux_2to1 u11_mux_2to1 (
        .digit_ones(w_temp_ultra_digit_out),
        .digit_tens(w_time_digit_out),
        .digit_sel (watch_sensor_sw),
        .digit_out (w_digit_out)
    );

    BCD u10_BCD (
        .data_in(w_digit_out),
        .seg    (seg_raw)
    );

    tick_1ms u11_tick_1ms (
        .clk     (clk),
        .rst_n   (rst_n),
        .tick_1ms(w_tick_1ms)
    );

    counter_8 u12_counter_8 (
        .clk      (w_tick_1ms),
        .rst_n    (rst_n),
        .digit_sel(w_digit_sel)
    );

    decoder_2to4 u13_decoder_2to4 (
        .digit_sel(w_digit_sel[1:0]),
        .digit    (digit)
    );
endmodule
