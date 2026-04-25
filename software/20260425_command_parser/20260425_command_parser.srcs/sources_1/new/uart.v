`timescale 1ns / 1ps

// 115200-8-N-1
module uart #(
    parameter CLOCK_FREQ_HZ = 100_000_000,
    parameter BAUD_RATE = 115200
) (
    input  wire clk,
    input  wire rst_n,
    input  wire rx,
    output wire tx,

    // start flag
    input wire tx_send,

    input  wire [7:0] tx_data,
    output wire [7:0] rx_data,

    // state
    output wire rx_done,
    output wire rx_frame_error,
    output wire tx_busy,
    output wire tx_overrun_error
);

    wire w_baud_tick_acc;

    uart_baud_rate_acc #(
        .CLOCK_FREQ_HZ(CLOCK_FREQ_HZ),
        .BAUD_RATE(BAUD_RATE)
    ) u1_uart_baud_rate_acc (
        .clk(clk),
        .rst_n(rst_n),
        .baud_tick(w_baud_tick_acc)
    );

    uart_rx u2_uart_rx (
        .clk(clk),
        .rst_n(rst_n),
        .rx_baud_tick(w_baud_tick_acc),
        .rx(rx),
        .rx_done(rx_done),
        .rx_data(rx_data),
        .rx_frame_error(rx_frame_error)
    );

    uart_tx u3_uart_tx (
        .clk(clk),
        .rst_n(rst_n),
        .tx_baud_tick(w_baud_tick_acc),
        .tx_data(tx_data),
        .tx_send(tx_send),
        .tx_busy(tx_busy),
        .tx_overrun_error(tx_overrun_error),
        .tx(tx)
    );
endmodule
