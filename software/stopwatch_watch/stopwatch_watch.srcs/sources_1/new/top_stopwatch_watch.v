`timescale 1ns / 1ps

module top_stopwatch_watch (
    input wire clk,
    input wire rst_n,

    input wire btnR,
    input wire btnL,
    input wire btnU,
    input wire btnD,

    input wire undefine_sw,
    input wire stopwatch_watch_sw,
    input wire hourmin_secmsec_sw,

    output wire [7:0] seg,
    output wire [3:0] digit,
    output wire [1:0] led
);

    wire [6:0] w_stopwatch_msec;
    wire [5:0] w_stopwatch_sec;
    wire [5:0] w_stopwatch_min;
    wire [4:0] w_stopwatch_hour;

    wire [6:0] w_watch_msec;
    wire [5:0] w_watch_sec;
    wire [5:0] w_watch_min;
    wire [4:0] w_watch_hour;

    wire [6:0] w_msec;
    wire [5:0] w_sec;
    wire [5:0] w_min;
    wire [4:0] w_hour;

    // stopwatch control signals
    wire       w_run;
    wire       w_clear;
    wire       w_mode;

    // watch control signals
    wire [2:0] w_digit_sel;
    wire       w_up;
    wire       w_down;

    // button pulse signals
    wire       w_btnR;
    wire       w_btnL;
    wire       w_btnU;
    wire       w_btnD;

    stopwatch_datapath u1_stopwatch_datapath (
        .clk  (clk),
        .rst_n(rst_n),
        .run  (w_run),
        .clear(w_clear),
        .mode (w_mode),
        .msec (w_stopwatch_msec),
        .sec  (w_stopwatch_sec),
        .min  (w_stopwatch_min),
        .hour (w_stopwatch_hour)
    );

    watch_datapath u1_watch_datapath (
        .clk      (clk),
        .rst_n    (rst_n),
        .set_mode (undefine_sw),
        .up       (w_up),
        .down     (w_down),
        .digit_sel(w_digit_sel),
        .msec     (w_watch_msec),
        .sec      (w_watch_sec),
        .min      (w_watch_min),
        .hour     (w_watch_hour)
    );

    stopwatch_watch_mux u_stopwatch_watch_mux (
        .stopwatch_msec(w_stopwatch_msec),
        .stopwatch_sec (w_stopwatch_sec),
        .stopwatch_min (w_stopwatch_min),
        .stopwatch_hour(w_stopwatch_hour),

        .watch_msec(w_watch_msec),
        .watch_sec (w_watch_sec),
        .watch_min (w_watch_min),
        .watch_hour(w_watch_hour),

        .sel(stopwatch_watch_sw),  // 1: stopwatch, 0: watch

        .msec(w_msec),
        .sec (w_sec),
        .min (w_min),
        .hour(w_hour)
    );

    assign led[0] = ~stopwatch_watch_sw;  // 1: watch, 0: stopwatch
    assign led[1] = hourmin_secmsec_sw;  // 1: sec/msec, 0: hour/min

    control_unit_stopwatch u1_stopwatch_control_unit (
        .clk         (clk),
        .rst_n       (rst_n),
        .btn_run     (w_btnR),
        .btn_clear   (w_btnL),
        .btn_mode    (w_btnD),
        .btn_undefine(),
        .sw_undefine (),
        .run         (w_run),
        .clear       (w_clear),
        .mode        (w_mode)
    );

    control_unit_watch u1_watch_control_unit (
        .clk      (clk),
        .rst_n    (rst_n),
        .btn_right(w_btnR),
        .btn_left (w_btnL),
        .btn_down (w_btnD),
        .btn_up   (w_btnU),
        .set_mode (undefine_sw),
        .digit_sel(w_digit_sel),
        .up       (w_up),
        .down     (w_down)
    );

    FND_Controller u3_FND_Controller (
        .clk          (clk),
        .rst_n        (rst_n),
        .msec         (w_msec),
        .sec          (w_sec),
        .min          (w_min),
        .hour         (w_hour),
        .time_unit_sel(hourmin_secmsec_sw),  // 1: sec/msec, 0: hour/min
        .digit        (digit),
        .seg          (seg)
    );

    btn_interface u1_btnR (
        .clk      (clk),
        .rst_n    (rst_n),
        .btn_in   (btnR),
        .btn_pulse(w_btnR)
    );

    btn_interface u1_btnL (
        .clk      (clk),
        .rst_n    (rst_n),
        .btn_in   (btnL),
        .btn_pulse(w_btnL)
    );

    btn_interface u1_btnU (
        .clk      (clk),
        .rst_n    (rst_n),
        .btn_in   (btnU),
        .btn_pulse(w_btnU)
    );

    btn_interface u1_btnD (
        .clk      (clk),
        .rst_n    (rst_n),
        .btn_in   (btnD),
        .btn_pulse(w_btnD)
    );

endmodule
