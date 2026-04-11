`timescale 1ns / 1ps

module counter_10000 (
    input wire clk,
    input wire rst_n,
    input wire stop,
    input wire reset,
    input wire mode_sel,
    output wire [3:0] digit,
    output wire [7:0] seg
);

    wire [13:0] w_tick_count;

    data_path u1_data_path (
        .clk(clk),
        .rst_n(rst_n),
        .stop(stop),
        .reset(reset),
        .mode_sel(mode_sel),
        .tick_count(w_tick_count)
    );

    FND_Controller u2_FND_Controller (
        .clk  (clk),
        .rst_n(rst_n),
        .data (w_tick_count),
        .digit(digit),
        .seg  (seg)
    );

endmodule
