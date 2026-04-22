`timescale 1ns / 1ps

module top_uart_tx_shift (
    input wire clk,
    input wire rst_n,
    output wire tx,
    output wire rx
);
    wire w_b_tick;

    baud_tick_gen_2 #(
        .CLOCK_FREQ_HZ(100_000_000),
        .BAUD_RATE    (9600)
    ) u1_baud_tick_gen_2 (
        .clk      (clk),
        .rst_n    (rst_n),
        .b_rx_tick(w_b_tick)
    );
/*
    uart_tx_counter u1_uart_tx_counter (
        .clk     (clk),
        .rst_n   (rst_n),
        .b_tick  (w_b_tick),
        .tx_start(tx_start),
        .tx_busy (tx_busy),
        .tx_data (tx_data),   // ascii '0'
        .tx      (tx)
    );

    uart_rx_2 u1_uart_rx (
        .clk(clk),
        .rst_n(rst_n),
        .b_tick(w_b_tick),
        .rx_data(rx_data),
        .rx_done(rx_done),
        .rx(rx)
    );

*/

    wire [7:0] tx_data;
    wire rx_done;

    uart_tx_counter u1_uart_tx_counter (
        .clk     (clk),
        .rst_n   (rst_n),
        .b_tick  (w_b_tick),
        .tx_start(rx_done),
        .tx_busy (),
        .tx_data (tx_data),   // ascii '0'
        .tx      (tx)
    );

    uart_rx_2 u1_uart_rx (
        .clk(clk),
        .rst_n(rst_n),
        .b_tick(w_b_tick),
        .rx_data(tx_data),
        .rx_done(rx_done),
        .rx(rx)
    );
endmodule
