`timescale 1ns / 1ps

module watch_datapath (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       sec_up_down,
    input  wire       min_up_down,
    input  wire       hour_up_down,
    output wire [6:0] msec,
    output wire [5:0] sec,
    output wire [5:0] min,
    output wire [4:0] hour
);

    wire w_tick_100hz;

    tick_gen_100hz #(
        .CLOCK_FREQ_HZ(100_000_000),
        .COUNT_HZ     (100)
    ) u1_tick_gen_100hz (
        .clk       (clk),
        .rst_n     (rst_n),
        .clear     (clear),
        .tick_100hz(w_tick_100hz)
    );

    n_modulo_counter_watch #(
        .N(100),
        .TIME_SET(0)
    ) u2_msec (
        .clk      (clk),
        .rst_n    (rst_n),
        .en       (w_tick_100hz),
        .count_set(1'b0),
        .clear    (clear),
        .count    (msec),
        .tick     (w_sec)
    );

    n_modulo_counter_watch #(
        .N(60),
        .TIME_SET(0)
    ) u3_sec (
        .clk      (clk),
        .rst_n    (rst_n),
        .en       (w_sec),
        .count_set(sec_up_down),
        .clear    (clear),
        .count    (sec),
        .tick     (w_min)
    );

    n_modulo_counter_watch #(
        .N(60),
        .TIME_SET(0)
    ) u4_min (
        .clk      (clk),
        .rst_n    (rst_n),
        .en       (w_min),
        .count_set(min_up_down),
        .clear    (clear),
        .count    (min),
        .tick     (w_hour)
    );

    n_modulo_counter_watch #(
        .N(24),
        .TIME_SET(12)
    ) u5_hour (
        .clk      (clk),
        .rst_n    (rst_n),
        .en       (w_hour),
        .count_set(hour_up_down),
        .clear    (clear),
        .count    (hour),
        .tick     ()
    );

endmodule
