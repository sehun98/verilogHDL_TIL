`timescale 1ns / 1ps

module uart_fifo_loopback (
    input wire clk,
    input wire rst_n,
    input wire rx,
    output wire tx,
    output [2:0] led
);

    localparam DEPTH = 4;
    localparam DEBUG_DELAY = 100;

    wire [7:0] w_rx_data;
    wire [7:0] w_rx_pop_data;
    wire [7:0] w_tx_pop_data;

    wire w_rx_done;
    wire w_tx_full;
    wire w_rx_empty;
    wire w_tx_empty;

    wire w_tx_busy;

    uart #(
        .CLOCK_FREQ_HZ(100_000_000),
        .BAUD_RATE(115200)
    ) u1_uart (
        .clk(clk),
        .rst_n(rst_n),
        .rx(rx),
        .tx(tx),

        .tx_send(~w_tx_empty),
        .tx_data(w_tx_pop_data),
        .tx_busy(w_tx_busy),

        .rx_data(w_rx_data),
        .rx_done(w_rx_done),

        .rx_frame_error(),
        .tx_overrun_error()
    );

    fifo #(
        .DEPTH(DEPTH)
    ) u1_fifo_rx (
        .clk(clk),
        .reset(rst_n),

        .push_data(w_rx_data),
        .push(w_rx_done),

        .pop(~w_tx_full),
        .pop_data(w_rx_pop_data),
        .full(),
        .empty(w_rx_empty)
    );

    fifo #(
        .DEPTH(DEPTH)
    ) u1_fifo_tx (
        .clk(clk),
        .reset(rst_n),

        .push_data(w_rx_pop_data),
        .push(~w_rx_empty),
        .pop(~w_tx_busy),
        .pop_data(w_tx_pop_data),
        .full(w_tx_full),
        .empty(w_tx_empty)
    );


endmodule
