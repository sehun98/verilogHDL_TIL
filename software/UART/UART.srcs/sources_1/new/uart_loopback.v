`timescale 1ns / 1ps

module uart_loopback(
    input wire clk,
    input wire rst_n,
    input wire rx,
    output wire tx,
    output [2:0] led
);

wire [7:0] w_tx_send;
wire w_done;

uart #(
    .CLOCK_FREQ_HZ(100_000_000),
    .BAUD_RATE(115200)
) u1_uart (
    .clk(clk),
    .rst_n(rst_n),
    .rx(rx),
    .tx(tx),

    .tx_send(w_done),
    .tx_data(w_tx_send),
    .rx_data(w_tx_send),
    .rx_done(w_done),
    .rx_frame_error(led[0]),
    .tx_busy(led[2]),
    .tx_overrun_error(led[1])
);

endmodule
