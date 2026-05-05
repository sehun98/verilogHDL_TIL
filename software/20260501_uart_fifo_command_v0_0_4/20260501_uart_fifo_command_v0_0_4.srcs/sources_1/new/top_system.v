`timescale 1ns / 1ps

module top_system (
    input wire clk,
    input wire rst_n,
    output wire [3:0] digit,
    output wire [7:0] seg,
    output wire [1:0] led,

    input wire btnR,
    input wire btnL,
    input wire btnU,
    input wire btnD,

    input wire setmode_sw,
    input wire stopwatch_watch_sw,
    input wire hourmin_secmsec_sw,
    input wire ultra_temp_sel_sw,
    input wire watch_sensor_sw,

    inout  wire dht11,
    output wire trig,
    input  wire echo,

    input  wire rx,
    output wire tx
);
    // line length max size
    localparam LINE_MAX = 64;

    // fifo depth size
    localparam DEPTH = 16;

    // from uart to rx fifo
    wire w_rx_done;
    wire [7:0] w_rx_data;

    // from tx fifo to uart 
    wire w_tx_send;
    wire [7:0] w_tx_data;

    // from rx fifo to line collector
    wire w_fifo_r_en;
    wire [7:0] w_fifo_data;
    wire w_fifo_empty;

    // from line collector to command parser
    wire [8*LINE_MAX-1:0] w_line_data;
    wire [$clog2(LINE_MAX+1)-1:0] w_line_length;
    wire w_line_valid;

    // from command parser to command executor
    wire [15:0] w_cmd_data_1;
    wire [15:0] w_cmd_data_2;
    wire [15:0] w_cmd_data_3;
    wire [15:0] w_cmd_data_4;

    // from stopwatch and watch to executor 
    wire [6:0] w_msec_data;
    wire [5:0] w_sec_data;
    wire [5:0] w_min_data;
    wire [4:0] w_hour_data;

    // from uart tx controller to stopwatch and watch 
    wire [6:0] w_o_msec_data;
    wire [5:0] w_o_sec_data;
    wire [5:0] w_o_min_data;
    wire [4:0] w_o_hour_data;

    // from command parser to command executor
    wire [3:0] w_cmd_type;
    wire w_cmd_valid;

    // from executor to stopwatch command
    wire w_stopwatch_run;
    wire w_stopwatch_clear;
    wire w_stopwatch_mode;

    // from executor to watch command
    wire w_uart_set_en;

    // uart tx to tx fifo 
    wire w_tx_busy;

    // from executor to uart tx controller
    wire w_error_send;

    // from uart tx controller to tx fifo
    wire w_tx_controller_fifo_full;
    wire w_tx_controller_fifo_w_en;
    wire [7:0] w_tx_controller_fifo_data;

    // from command executro to stopwatch and watch time data request signal
    wire w_watch_time_request;

    // from command executor to ultrasonic request signal
    wire w_ultrasonic_request;

    // from command executor to dht11 request signal
    wire w_dht11_request;

    // from ultrasonic to uart tx controller done signal
    wire w_ultrasonic_done;

    // from dht11 to uart tx controller done signal  
    wire w_dht11_done;

    // from stopwatch and watch to uart tx controller
    wire [8:0] w_distance_data;
    wire [7:0] w_temp_data;
    wire [7:0] w_humidity_data;

    top_stopwatch_watch u1_top_stopwatch_watch (
        .clk  (clk),
        .rst_n(rst_n),

        .btnR(btnR),
        .btnL(btnL),
        .btnU(btnU),
        .btnD(btnD),

        .setmode_sw        (setmode_sw),
        .stopwatch_watch_sw(stopwatch_watch_sw),
        .hourmin_secmsec_sw(hourmin_secmsec_sw),
        .ultra_temp_sel_sw (ultra_temp_sel_sw),
        .watch_sensor_sw   (watch_sensor_sw),

        .i_hour_data(w_hour_data),
        .i_min_data (w_min_data),
        .i_sec_data (w_sec_data),
        .i_msec_data(w_msec_data),

        .o_hour_data(w_o_hour_data),
        .o_min_data (w_o_min_data),
        .o_sec_data (w_o_sec_data),
        .o_msec_data(w_o_msec_data),

        .uart_set_en       (w_uart_set_en),
        .ultrasonic_request(w_ultrasonic_request),
        .dht11_request     (w_dht11_request),

        .ultrasonic_done(w_ultrasonic_done),
        .dht11_done     (w_dht11_done),

        .distance_data(w_distance_data),
        .temp_data    (w_temp_data),
        .humidity_data(w_humidity_data),

        .uart_stopwatch_run  (w_stopwatch_run),
        .uart_stopwatch_clear(w_stopwatch_clear),
        .uart_stopwatch_mode (w_stopwatch_mode),

        .dht11(dht11),
        .trig (trig),
        .echo (echo),

        .seg  (seg),
        .digit(digit),
        .led  (led)
    );

    uart #(
        .CLOCK_FREQ_HZ(100_000_000),
        .BAUD_RATE(115200)
    ) u2_uart (
        .clk  (clk),
        .rst_n(rst_n),
        .rx   (rx),
        .tx   (tx),

        .tx_send(~w_tx_send),
        .tx_data(w_tx_data),

        .rx_data(w_rx_data),
        .rx_done(w_rx_done),

        .rx_frame_error  (),
        .tx_busy         (w_tx_busy),
        .tx_overrun_error()
    );

    // combinational read FIFO
    fifo #(
        .DEPTH(DEPTH)
    ) u3_rx_fifo (
        .clk  (clk),
        .rst_n(rst_n),

        .push     (w_rx_done),
        .push_data(w_rx_data),

        .pop     (w_fifo_r_en),
        .pop_data(w_fifo_data),

        .empty(w_fifo_empty),
        .full ()
    );

    // combinational read FIFO
    fifo #(
        .DEPTH(DEPTH)
    ) u4_tx_fifo (
        .clk  (clk),
        .rst_n(rst_n),

        .push     (w_tx_controller_fifo_w_en),
        .push_data(w_tx_controller_fifo_data),

        .pop     (~w_tx_busy),
        .pop_data(w_tx_data),

        .empty(w_tx_send),
        .full (w_tx_controller_fifo_full)
    );

    line_collector #(
        .LINE_MAX(LINE_MAX)
    ) u5_line_collector (
        .clk  (clk),
        .rst_n(rst_n),

        .fifo_r_en (w_fifo_r_en),
        .fifo_data (w_fifo_data),
        .fifo_empty(w_fifo_empty),

        .line_data  (w_line_data),
        .line_length(w_line_length),
        .line_valid (w_line_valid)
    );

    command_parser #(
        .LINE_MAX(LINE_MAX)
    ) u6_command_parser (
        .clk  (clk),
        .rst_n(rst_n),

        .line_data  (w_line_data),
        .line_length(w_line_length),
        .line_valid (w_line_valid),

        .o_cmd_data_1(w_cmd_data_1),
        .o_cmd_data_2(w_cmd_data_2),
        .o_cmd_data_3(w_cmd_data_3),
        .o_cmd_data_4(w_cmd_data_4),

        .cmd_type (w_cmd_type),
        .cmd_valid(w_cmd_valid),
        .cmd_error()
    );

    command_executor u7_command_executor (
        .clk  (clk),
        .rst_n(rst_n),

        .uart_set_en       (w_uart_set_en),
        .watch_time_request(w_watch_time_request),
        .ultrasonic_request(w_ultrasonic_request),
        .dht11_request     (w_dht11_request),

        .i_cmd_data_1(w_cmd_data_1),
        .i_cmd_data_2(w_cmd_data_2),
        .i_cmd_data_3(w_cmd_data_3),
        .i_cmd_data_4(w_cmd_data_4),

        .o_hour_data(w_hour_data),
        .o_min_data (w_min_data),
        .o_sec_data (w_sec_data),
        .o_msec_data(w_msec_data),

        .cmd_type (w_cmd_type),
        .cmd_valid(w_cmd_valid),

        .stopwatch_run  (w_stopwatch_run),
        .stopwatch_clear(w_stopwatch_clear),
        .stopwatch_mode (w_stopwatch_mode),

        .exec_done (),
        .error_send(w_error_send)
    );

    UART_TX_Controller u8_UART_TX_Controller (
        .clk  (clk),
        .rst_n(rst_n),

        .error_send(w_error_send),

        .watch_time_request(w_watch_time_request),
        .ultrasonic_done   (w_ultrasonic_done),
        .dht11_done        (w_dht11_done),

        .i_hour_data(w_o_hour_data),
        .i_min_data (w_o_min_data),
        .i_sec_data (w_o_sec_data),
        .i_msec_data(w_o_msec_data),

        .i_temp_data    (w_temp_data),
        .i_humidity_data(w_humidity_data),
        .i_distance_data(w_distance_data),

        .fifo_full(w_tx_controller_fifo_full),
        .fifo_w_en(w_tx_controller_fifo_w_en),
        .fifo_data(w_tx_controller_fifo_data)
    );
endmodule
