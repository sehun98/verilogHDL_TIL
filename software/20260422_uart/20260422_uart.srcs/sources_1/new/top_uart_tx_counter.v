`timescale 1ns / 1ps

module top_uart_tx_counter (
    input  wire clk,
    input  wire rst_n,
    input  wire btnR,
    input  wire [7:0] tx_data,
    output wire tx
);
    wire w_b_tx_tick;
    wire w_btnR;

    baud_tick_gen #(
        .CLOCK_FREQ_HZ(100_000_000),
        .BAUD_RATE    (9600)
    ) u1_baud_tick_gen (
        .clk     (clk),
        .rst_n   (rst_n),
        .b_tx_tick(w_b_tx_tick),
        .b_rx_tick(w_b_rx_tick)
    );

    uart_tx_counter u1_uart_tx_counter (
        .clk     (clk),
        .rst_n   (rst_n),
        .b_tick(w_b_tx_tick),
        .tx_start(w_btnR),
        .tx_data (tx_data),     // ascii '0'
        .tx      (tx)
    );

    btn_interface u1_btn_interface (
        .clk      (clk),
        .rst_n    (rst_n),
        .btn_in   (btnR),
        .btn_pulse(w_btnR)
    );

endmodule
