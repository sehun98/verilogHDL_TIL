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
    wire                          w_r_en;
    wire [                   7:0] w_dout;
    wire                          w_empty;
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

        .tx_send(w_rx_done),
        .tx_data(w_rx_data),
        
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

        .r_en (w_r_en),
        .dout (w_dout),
        
        .empty(w_empty),
        .full ()
    );

    line_collector #(
        .LINE_MAX(LINE_MAX)
    ) u4_line_collector (
        .clk(clk),
        .rst_n(rst_n),

        .fifo_r_en(w_r_en), // en 신호를 인가하면 fifo로 부터 데이터가 들어온다.
        .fifo_data(w_dout),  // 읽오는 데이터
        .fifo_empty(w_empty), // high 일 때 비어 있으므로 데이터를 읽지 말아야 한다.

        .line_data(w_line_data), // 문장이 완성된 데이터를 전송해준다.
        .line_length(w_line_length),  // 문장의 길이를 전송해준다.
        .line_valid(w_line_valid) // 문장이 완성되지 않았을 때 valid를 0으로 유지 시킨다, 문장이 전송이 되어도 0이 된다.
    );

    command_parser #(
        .LINE_MAX(LINE_MAX)
    ) u5_command_parser (
        .clk(clk),
        .rst_n(rst_n),
        .line_data(w_line_data),
        .line_length(w_line_length),
        .line_valid(w_line_valid),
        .cmd_data(w_cmd_data),  // 0~65535
        .cmd_type(w_cmd_type),  // 0~15
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
        .status_req(),
        .reset_req(),
        .exec_done()
    );

endmodule
