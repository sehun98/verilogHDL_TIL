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

    input  wire rx,
    output wire tx
);
    localparam LINE_MAX = 64;
    localparam DEPTH = 16;

    wire [                  13:0] w_data;
    wire                          w_rx_done;
    wire [                   7:0] w_rx_data;
    wire                          w_tx_send;
    wire [                   7:0] w_tx_data;
    wire                          w_fifo_r_en;
    wire [                   7:0] w_fifo_data;
    wire                          w_fifo_empty;
    wire                          w_tx_w_en;
    wire [                   7:0] w_tx_din;
    wire                          w_tx_full;
    wire [        8*LINE_MAX-1:0] w_line_data;
    wire [$clog2(LINE_MAX+1)-1:0] w_line_length;
    wire                          w_line_valid;

    wire [                  15:0] w_cmd_data_1;
    wire [                  15:0] w_cmd_data_2;
    wire [                  15:0] w_cmd_data_3;
    wire [                  15:0] w_cmd_data_4;

    wire [                  15:0] w_msec_data;
    wire [                  15:0] w_sec_data;
    wire [                  15:0] w_min_data;
    wire [                  15:0] w_hour_data;

    wire [                  15:0] w_o_msec_data;
    wire [                  15:0] w_o_sec_data;
    wire [                  15:0] w_o_min_data;
    wire [                  15:0] w_o_hour_data;

    wire [                   3:0] w_cmd_type;
    wire                          w_cmd_valid;
    wire [                  13:0] w_fnd_value;

    wire                          w_run;
    wire                          w_clear;
    wire                          w_mode;

    wire                          w_uart_set_en;

    wire                          w_tx_busy;

    wire                          w_error_send;

    wire                          w_tx_controller_fifo_full;
    wire                          w_tx_controller_fifo_w_en;
    wire [                   7:0] w_tx_controller_fifo_data;

    wire w_watch_time_request;  

    wire w_ultrasonic_request; // executor to ultrasonic request signal
    wire w_dht11_request; // executor to dht11 request signal
    wire w_ultrasonic_done; // ultrasonic to uart tx controller done signal
    wire w_dht11_done; // dht11 to uart tx controller done signal

    top_stopwatch_watch u1_top_stopwatch_watch (
        .clk  (clk),
        .rst_n(rst_n),

        .btnR(btnR),
        .btnL(btnL),
        .btnU(btnU),
        .btnD(btnD),

        .run  (w_run),
        .clear(w_clear),
        .mode (w_mode),

        .uart_set_en(w_uart_set_en),

        .i_hour_data(w_hour_data[4:0]),
        .i_min_data (w_min_data[5:0]),
        .i_sec_data (w_sec_data[5:0]),
        .i_msec_data(w_msec_data[6:0]),
        
        .o_hour_data(w_o_hour_data),
        .o_min_data (w_o_min_data),
        .o_sec_data (w_o_sec_data),
        .o_msec_data(w_o_msec_data),

        .setmode_sw(setmode_sw),
        .stopwatch_watch_sw(stopwatch_watch_sw),
        .hourmin_secmsec_sw(hourmin_secmsec_sw),

        .seg  (seg),
        .digit(digit),
        .led  (led)
    );

    uart #(
        .CLOCK_FREQ_HZ(100_000_000),
        .BAUD_RATE(115200)
    ) u2_uart (
        .clk(clk),
        .rst_n(rst_n),
        .rx(rx),
        .tx(tx),

        .tx_send(~w_tx_send),
        .tx_data(w_tx_data),

        .rx_data(w_rx_data),
        .rx_done(w_rx_done),

        .rx_frame_error(),
        .tx_busy(w_tx_busy),
        .tx_overrun_error()
    );

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
    ) u4_line_collector (
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
    ) u5_command_parser (
        .clk(clk),
        .rst_n(rst_n),
        .line_data(w_line_data),
        .line_length(w_line_length),
        .line_valid(w_line_valid),

        .cmd_data_1(w_cmd_data_1),
        .cmd_data_2(w_cmd_data_2),
        .cmd_data_3(w_cmd_data_3),
        .cmd_data_4(w_cmd_data_4),

        .cmd_type (w_cmd_type),
        .cmd_valid(w_cmd_valid),
        .cmd_error()
    );

    command_executor u6_command_executor (
        .clk  (clk),
        .rst_n(rst_n),

        .uart_set_en(w_uart_set_en),
        .watch_time_request(w_watch_time_request),
        .ultrasonic_request(w_ultrasonic_request),
        .dht11_request(w_dht11_request),

        .i_cmd_data_1(w_cmd_data_1),
        .i_cmd_data_2(w_cmd_data_2),
        .i_cmd_data_3(w_cmd_data_3),
        .i_cmd_data_4(w_cmd_data_4),

        .o_cmd_data_1(w_hour_data[4:0]),
        .o_cmd_data_2(w_min_data[5:0]),
        .o_cmd_data_3(w_sec_data[5:0]),
        .o_cmd_data_4(w_msec_data[6:0]),

        .cmd_type (w_cmd_type),
        .cmd_valid(w_cmd_valid),

        .stopwatch_run  (w_run),
        .stopwatch_clear(w_clear),
        .stopwatch_mode (w_mode),

        .exec_done (),
        .error_send(w_error_send)
    );

    UART_TX_Controller u7_UART_TX_Controller (
        .clk(clk),
        .rst_n(rst_n),

        .error_send(w_error_send),

        .watch_time_request(w_watch_time_request),
        .ultrasonic_done(w_ultrasonic_done),
        .dht11_done(w_dht11_done),

        .i_hour_data(w_o_hour_data),
        .i_min_data (w_o_min_data),
        .i_sec_data (w_o_sec_data),
        .i_msec_data(w_o_msec_data),

        .fifo_full(w_tx_controller_fifo_full),
        .fifo_w_en(w_tx_controller_fifo_w_en),
        .fifo_data(w_tx_controller_fifo_data)
    );

endmodule
