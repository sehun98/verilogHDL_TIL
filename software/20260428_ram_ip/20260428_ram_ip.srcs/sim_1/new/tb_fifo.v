`timescale 1ns / 1ps

module tb_fifo;
    wire       clk;
    wire       rst_n;
    wire [7:0] w_data;
    reg  [7:0] r_data;
    wire       w_e;
    wire       r_e;
    wire       empty;
    wire       full;

    fifo u1_fifo (
        .clk(clk),
        .rst_n(rst_n),
        .w_data(w_data),
        .r_data(r_data),
        .w_e(w_e),
        .r_e(r_e),
        .empty(empty),
        .full(full)
    );

endmodule
