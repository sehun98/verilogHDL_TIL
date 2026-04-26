`timescale 1ns / 1ps

module top_system (
    input wire clk,
    input wire rst_n,
    output wire [3:0] digit,
    output wire [7:0] seg,
    output wire [3:0] led,
    input wire rx,
    output wire tx
);
    localparam LINE_MAX = 64;
    wire [                  13:0] w_data;
    wire                          w_rx_done;
    wire [                   7:0] w_rx_data;
    wire                          w_tx_send;
    wire [                   7:0] w_tx_data;
    wire                          w_rx_r_en;
    wire [                   7:0] w_rx_dout;
    wire                          w_rx_empty;
    wire                          w_tx_w_en;
    wire [                   7:0] w_tx_din;
    wire                          w_tx_full;
    wire [        8*LINE_MAX-1:0] w_line_data;
    wire [$clog2(LINE_MAX+1)-1:0] w_line_length;
    wire                          w_line_valid;
    wire [                  15:0] w_cmd_data;
    wire [                   3:0] w_cmd_type;
    wire                          w_cmd_valid;
    wire [                  13:0] w_fnd_value;

    FND_Controller u1_FND_Controller (
        .clk  (clk),
        .rst_n(rst_n),
        .data (w_fnd_value),
        .digit(digit),
        .seg  (seg)
    );

    uart #(
        .CLOCK_FREQ_HZ(100_000_000),
        .BAUD_RATE(115200)
    ) u2_uart (
        .clk(clk),
        .rst_n(rst_n),
        .rx(rx),
        .tx(tx),

        .tx_send(w_tx_send),
        .tx_data(w_tx_data),
        
        .rx_data(w_rx_data),
        .rx_done(w_rx_done),

        .rx_frame_error(),
        .tx_busy(),
        .tx_overrun_error()
    );

    fifo u3_rx_fifo (
        .clk  (clk),
        .rst_n(rst_n),

        .w_en (w_rx_done),
        .din  (w_rx_data),

        .r_en (w_rx_r_en),
        .dout (w_rx_dout),
        
        .empty(w_rx_empty),
        .full ()
    );

    fifo u4_tx_fifo (
        .clk  (clk),
        .rst_n(rst_n),

        .w_en (w_tx_w_en),
        .din  (w_tx_din),

        .r_en (w_tx_send),
        .dout (w_tx_data),
        
        .empty(),
        .full (w_tx_full)
    );

    line_collector #(
        .LINE_MAX(LINE_MAX)
    ) u4_line_collector (
        .clk(clk),
        .rst_n(rst_n),

        .fifo_r_en(w_rx_r_en), 
        .fifo_data(w_rx_dout),
        .fifo_empty(w_rx_empty),

        .line_data(w_line_data),
        .line_length(w_line_length), 
        .line_valid(w_line_valid) 
    );

    command_parser #(
        .LINE_MAX(LINE_MAX)
    ) u5_command_parser (
        .clk(clk),
        .rst_n(rst_n),
        .line_data(w_line_data),
        .line_length(w_line_length),
        .line_valid(w_line_valid),
        .cmd_data(w_cmd_data),
        .cmd_type(w_cmd_type), 
        .cmd_valid(w_cmd_valid),
        .cmd_error()
    );

    command_executor u6_command_executor (
        .clk(clk),
        .rst_n(rst_n),
        .cmd_data(w_cmd_data),
        .cmd_type(w_cmd_type),
        .cmd_valid(w_cmd_valid),
        .led(led),
        .fnd_value(w_fnd_value),

        .fifo_full(w_tx_full),
        .fifo_w_en(w_tx_w_en),
        .fifo_data(w_tx_din),

        .status_req(),
        .reset_req(),
        .exec_done()
    );
endmodule
