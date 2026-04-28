`timescale 1ns / 1ps
// IDLE, START, DATA, STOP
// 

module uart_rx(
    input wire clk,
    input wire rst_n,
    input wire baud_tick,

    input wire rx,

    output wire [7:0] rx_data,
    output wire rx_done,
    output wire rx_frame_error
    );
endmodule
