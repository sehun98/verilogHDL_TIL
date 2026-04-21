`timescale 1ns / 1ps

module uart_fifo_top (
    input  wire clk,
    input  wire rst_n,
    output wire tx,
    input  wire rx
);
    wire w_tx_baud_tick;
    wire w_rx_baud_tick;

    wire w_busy_rx;
    wire w_busy_tx;

    wire w_done_rx;
    wire w_done_tx;

    wire [7:0] w_data_rx;
    wire [7:0] w_data_tx;

    wire w_send;

    wire w_empty;
    wire w_full;

    uart_baudrate_gen #(
        .CLOCK_FREQ_HZ(100_000_000),
        .BAUD_RATE(115200)
    ) u1_uart_baudrate_gen (
        .clk(clk),
        .rst_n(rst_n),
        .tx_baud_tick(w_tx_baud_tick),
        .rx_baud_tick(w_rx_baud_tick)
    );

    uart_rx u2_uart_rx (
        .clk(clk),
        .rst_n(rst_n),
        .rx_baud_tick(w_rx_baud_tick),
        .busy(w_busy_rx),

        .done(w_done_rx),
        .data(w_data_rx),
        .rx  (rx)
    );

    uart_tx u3_uart_tx (
        .clk(clk),
        .rst_n(rst_n),
        .tx_baud_tick(w_tx_baud_tick),

        .send(w_send),
        .busy(w_busy_tx),
        .done(w_done_tx),
        .data(w_data_tx),
        .tx  (tx)
    );

    fifo u4_fifo (
        .clk  (clk),
        .rst_n(rst_n),

        .din (w_data_rx),
        .w_en(w_done_rx),

        .dout(w_data_tx),
        .r_en(w_send),

        .empty(w_empty),
        .full (w_full)
    );

    assign w_send = ~w_empty & ~w_busy_tx;

endmodule
