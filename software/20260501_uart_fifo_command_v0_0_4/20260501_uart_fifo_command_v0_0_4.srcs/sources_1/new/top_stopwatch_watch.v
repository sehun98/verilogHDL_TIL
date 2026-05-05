`timescale 1ns / 1ps

module top_stopwatch_watch (
    input wire clk,
    input wire rst_n,

    input wire btnR,
    input wire btnL,
    input wire btnU,
    input wire btnD,

    input wire setmode_sw,
    input wire stopwatch_watch_sw,
    input wire hourmin_secmsec_sw,
    input wire ultra_temp_sel_sw,
    input wire watch_sensor_sw,

    // from command executor to stopwatch and watch 
    input wire [6:0] i_msec_data,  // msec
    input wire [5:0] i_sec_data,   // sec
    input wire [5:0] i_min_data,   // min
    input wire [4:0] i_hour_data,  // hour

    // from stopwatch and watch to uart tx controller
    output wire [6:0] o_msec_data,  // msec
    output wire [5:0] o_sec_data,   // sec
    output wire [5:0] o_min_data,   // min
    output wire [4:0] o_hour_data,  // hour

    // from command executor to stopwatch and watch 
    input wire uart_set_en,
    input wire ultrasonic_request,
    input wire dht11_request,

    // from stopwatch and watch to uart tx controller
    output wire ultrasonic_done,
    output wire dht11_done,

    // from stopwatch and watch to uart tx controller
    output wire [8:0] distance_data,
    output wire [7:0] temp_data,
    output wire [7:0] humidity_data,

    // from command executor to stopwatch and watch 
    input wire uart_stopwatch_run,
    input wire uart_stopwatch_clear,
    input wire uart_stopwatch_mode,

    inout  wire dht11,
    output wire trig,
    input  wire echo,

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

    // watch control signals
    wire [2:0] w_digit_sel;
    wire       w_up;
    wire       w_down;

    // button pulse signals
    wire       w_btnR;
    wire       w_btnL;
    wire       w_btnU;
    wire       w_btnD;

    wire       w_stopwatch_btnR;
    wire       w_stopwatch_btnL;
    wire       w_stopwatch_btnD;
    wire       w_watch_btnR;
    wire       w_watch_btnL;
    wire       w_watch_btnD;

    // stopwatch datapath signal
    wire       w_stopwatch_run;
    wire       w_stopwatch_clear;
    wire       w_stopwatch_mode;

    // fnd로 가는 data intercept
    assign o_msec_data = w_watch_msec;
    assign o_sec_data  = w_watch_sec;
    assign o_min_data  = w_watch_min;
    assign o_hour_data = w_watch_hour;

    stopwatch_datapath u1_stopwatch_datapath (
        .clk  (clk),
        .rst_n(rst_n),

        .run  (w_stopwatch_run),
        .clear(w_stopwatch_clear),
        .mode (w_stopwatch_mode),

        .msec(w_stopwatch_msec),
        .sec (w_stopwatch_sec),
        .min (w_stopwatch_min),
        .hour(w_stopwatch_hour)
    );

    watch_datapath u2_watch_datapath (
        .clk      (clk),
        .rst_n    (rst_n),
        .set_mode (setmode_sw),
        .up       (w_up),
        .down     (w_down),
        .digit_sel(w_digit_sel),

        .uart_set_en(uart_set_en),

        .i_hour_data(i_hour_data),
        .i_min_data (i_min_data),
        .i_sec_data (i_sec_data),
        .i_msec_data(i_msec_data),

        .msec(w_watch_msec),
        .sec (w_watch_sec),
        .min (w_watch_min),
        .hour(w_watch_hour)
    );

    stopwatch_watch_mux u3_stopwatch_watch_mux (
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

    control_unit_stopwatch u4_stopwatch_control_unit (
        .clk  (clk),
        .rst_n(rst_n),

        .uart_run  (uart_stopwatch_run),
        .uart_clear(uart_stopwatch_clear),
        .uart_mode (uart_stopwatch_mode),

        .btn_run     (w_stopwatch_btnR),
        .btn_clear   (w_stopwatch_btnL),
        .btn_mode    (w_stopwatch_btnD),
        .btn_undefine(),
        .sw_undefine (),
        .run         (w_stopwatch_run),
        .clear       (w_stopwatch_clear),
        .mode        (w_stopwatch_mode)
    );

    control_unit_watch u5_watch_control_unit (
        .clk      (clk),
        .rst_n    (rst_n),
        .btn_right(w_watch_btnR),
        .btn_left (w_watch_btnL),
        .btn_down (w_watch_btnD),
        .btn_up   (w_btnU),
        .set_mode (setmode_sw),
        .digit_sel(w_digit_sel),
        .up       (w_up),
        .down     (w_down)
    );

    FND_Controller u6_FND_Controller (
        .clk               (clk),
        .rst_n             (rst_n),
        .msec              (w_msec),
        .sec               (w_sec),
        .min               (w_min),
        .hour              (w_hour),
        .time_unit_sel     (hourmin_secmsec_sw),  // 1: sec/msec, 0: hour/min
        .set_mode_sw       (setmode_sw),
        .stopwatch_watch_sw(stopwatch_watch_sw),
        .ultra_temp_sel_sw (ultra_temp_sel_sw),
        .watch_sensor_sw   (watch_sensor_sw),
        .distance          (distance_data),
        .humidity          (humidity_data),
        .temperature       (temp_data),
        .dot_sel           (w_digit_sel),
        .digit             (digit),
        .seg               (seg)
    );

    demux_1to2 u7_demux_1to2 (
        .btnR          (w_btnR),
        .btnL          (w_btnL),
        .btnD          (w_btnD),
        .sel           (~stopwatch_watch_sw),
        .stopwatch_btnR(w_stopwatch_btnR),
        .stopwatch_btnL(w_stopwatch_btnL),
        .stopwatch_btnD(w_stopwatch_btnD),
        .watch_btnR    (w_watch_btnR),
        .watch_btnL    (w_watch_btnL),
        .watch_btnD    (w_watch_btnD)
    );

    btn_interface u8_btnR (
        .clk      (clk),
        .rst_n    (rst_n),
        .btn_in   (btnR),
        .btn_pulse(w_btnR)
    );

    btn_interface u9_btnL (
        .clk      (clk),
        .rst_n    (rst_n),
        .btn_in   (btnL),
        .btn_pulse(w_btnL)
    );

    btn_interface u10_btnU (
        .clk      (clk),
        .rst_n    (rst_n),
        .btn_in   (btnU),
        .btn_pulse(w_btnU)
    );

    btn_interface u11_btnD (
        .clk      (clk),
        .rst_n    (rst_n),
        .btn_in   (btnD),
        .btn_pulse(w_btnD)
    );

    dht11 u12_dht11 (
        .clk        (clk),
        .rst_n      (rst_n),
        .dht11_start(dht11_request),
        .dht11_done (dht11_done),
        .humidity   (humidity_data),
        .temperature(temp_data),
        .dht11      (dht11)
    );

    ultrasonic u13_ultrasonic (
        .clk             (clk),
        .rst_n           (rst_n),
        .ultrasonic_start(ultrasonic_request),
        .ultrasonic_done (ultrasonic_done),
        .distance        (distance_data),
        .trig            (trig),
        .echo            (echo)
    );

endmodule

