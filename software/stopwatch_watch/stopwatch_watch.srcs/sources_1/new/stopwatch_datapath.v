`timescale 1ns / 1ps

module stopwatch_datapath (
    input  wire       clk,
    input  wire       rst_n,

    input  wire       run,
    input  wire       clear,
    input  wire       mode,
    
    output wire [6:0] msec,
    output wire [5:0] sec,
    output wire [5:0] min,
    output wire [4:0] hour
);

    wire w_tick_100hz;
    wire w_tick_100hz_run;

    wire w_sec;
    wire w_min;
    wire w_hour;

    assign w_tick_100hz_run = run & w_tick_100hz;

    tick_gen_100hz #(
        .CLOCK_FREQ_HZ(100_000_000),
        .COUNT_HZ(100)
    ) u1_tick_gen_100hz (
        .clk       (clk),
        .rst_n     (rst_n),
        .clear     (clear),
        .tick_100hz(w_tick_100hz)
    );

    n_modulo_counter #(
        .N(100)
    ) u2_msec (
        .clk  (clk),
        .rst_n(rst_n),
        .en   (w_tick_100hz_run),
        .clear(clear),
        .mode(mode),
        .count(msec),
        .tick (w_sec)
    );

    n_modulo_counter #(
        .N(60)
    ) u3_sec (
        .clk  (clk),
        .rst_n(rst_n),
        .en   (w_sec),
        .clear(clear),
        .mode(mode),
        .count(sec),
        .tick (w_min)
    );

    n_modulo_counter #(
        .N(60)
    ) u4_min (
        .clk  (clk),
        .rst_n(rst_n),
        .en   (w_min),
        .clear(clear),
        .mode(mode),
        .count(min),
        .tick (w_hour)
    );

    n_modulo_counter #(
        .N(24)
    ) u5_hour (
        .clk  (clk),
        .rst_n(rst_n),
        .en   (w_hour),
        .clear(clear),
        .mode(mode),
        .count(hour),
        .tick ()
    );

endmodule
