`timescale 1ns / 1ps

module i2c_slave_top(
    input logic clk,
    input logic reset,

    input logic cmd_start,
    input logic cmd_write,
    input logic cmd_read,
    input logic cmd_stop,

    input  logic [7:0] tx_data,
    output logic [7:0] rx_data,

    input  logic ack_in,
    output logic ack_out,

    output logic busy,
    output logic done,

    input logic scl,
    inout  logic sda
    );

    logic sda_o, sda_i;
    assign sda_i = sda;
    assign sda   = sda_o ? 1'bz : 1'b0;

    i2c_master u1_i2c_master (
        .clk(clk),
        .reset(reset),
        .tx_data(tx_data),
        .rx_data(rx_data),
        .ack_in(ack_in),
        .ack_out(ack_out),
        .busy(busy),
        .done(done),
        .scl(scl),
        .sda_o(sda_o),
        .sda_i(sda_i)
    );

endmodule
/*
SCL 감시
SDA 감시
START 검출
주소 수신
ACK 응답
데이터 송수신
STOP 검출
*/
module i2c_slave (
    input logic clk,
    input logic reset,

    input  logic [7:0] tx_data,
    output logic [7:0] rx_data,

    input  logic ack_in,
    output logic ack_out,

    output logic busy,
    output logic done,

    output logic scl,
    output logic sda_o,
    input  logic sda_i
);

endmodule
