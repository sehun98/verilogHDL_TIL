`timescale 1ns / 1ps

module top_stopwatch_watch (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       btnR,
    input  wire       btnL,
    input  wire       btnU,
    input  wire       btnD,
    input  wire [2:0] sw,
    output wire [7:0] seg,
    output wire [3:0] digit,
    output wire [1:0] led
);
    wire [6:0] w_msec;
    wire [5:0] w_sec;
    wire [5:0] w_min;
    wire [4:0] w_hour;

    wire w_run;
    wire w_clear;
    wire w_mode;

    wire w_btnR;
    wire w_btnL;
    wire w_btnU;
    wire w_btnD;

    stopwatch_datapath u1_stopwatch_datapath (
        .clk  (clk),
        .rst_n(rst_n),
        .run  (w_run),
        .clear(w_clear),
        .mode (w_mode),
        .msec (w_msec),
        .sec  (w_sec),
        .min  (w_min),
        .hour (w_hour)
    );

    /*
    watch_datapath u1_watch_datapath (
        .clk  (clk),
        .rst_n(rst_n),
        .sec_up_down(sec_up_down),
        .min_up_down (min_up_down),
        .hour_up_down  (hour_up_down),
        .msec (w_msec),
        .sec  (w_sec),
        .min  (w_min),
        .hour (w_hour)
    );
*/

// tens digit msec, sec 오동작
    control_unit u1_control_unit (
        .clk           (clk),
        .rst_n         (rst_n),
        .btn_run       (w_btnR),
        .btn_clear     (w_btnL),
        .btn_mode      (w_btnD),
        .btn_not_define(w_btnU),
        .sw            (sw),
        .run           (w_run),
        .clear         (w_clear),
        .mode          (w_mode),
        .led           (led)
    );

    FND_Controller u3_FND_Controller (
        .clk          (clk),
        .rst_n        (rst_n),
        .msec         (w_msec),
        .sec          (w_sec),
        .min          (w_min),
        .hour         (w_hour),
        .time_unit_sel(sw[0]),   // High : msec/sec, LOW : min/hour
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
