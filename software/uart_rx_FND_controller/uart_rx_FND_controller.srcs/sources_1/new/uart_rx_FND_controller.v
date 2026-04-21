`timescale 1ns / 1ps

module uart_rx_FND_controller (
    input wire clk,
    input wire rst_n,
    input wire rx, // ASCII
    output wire [3:0] digit,
    output wire [7:0] seg
);
    wire w_rx_baud_tick;
    wire w_en;
    wire r_en;
    wire [7:0] w_data;
    wire [7:0] w_dout;


    uart_baudrate_gen #(
        .CLOCK_FREQ_HZ(100_000_000),
        .BAUD_RATE(115200)
    ) u1_uart_baudrate_gen (
        .clk(clk),
        .rst_n(rst_n),
        .tx_baud_tick(),
        .rx_baud_tick(w_rx_baud_tick)
    );

    uart_rx u2_uart_rx (
        .clk(clk),
        .rst_n(rst_n),
        .rx_baud_tick(w_rx_baud_tick),
        .busy(),
        .done(w_en),
        .data(w_data),
        .frame_error(),
        .rx(rx)
    );

    FND_Controller u3_FND_Controller (
        .clk  (clk),
        .rst_n(rst_n),
        .data (w_dout),
        .digit(digit),
        .seg  (seg)
    );

    fifo u4_fifo (
    .clk(clk),
    .rst_n(rst_n),

    .din(w_data),
    .w_en(w_en),

    .dout(w_dout),
    .r_en(r_en),

    .empty(),
    .full(r_en)
);

endmodule
