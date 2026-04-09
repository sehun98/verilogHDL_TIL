`timescale 1ns / 1ps

module counter_10000 (
    input wire clk,
    input wire rst_n,
    output wire [3:0] digit,
    output wire [7:0] seg
);

    wire [13:0] w_tick_count;

    data_path u1_data_path (
        .clk(clk),
        .rst_n(rst_n),
        .tick_count(w_tick_count)
    );

    FND_Controllor u2_FND_Controllor (
        .clk  (clk),
        .rst_n(rst_n),
        .data (w_tick_count),
        .digit(digit),
        .seg  (seg)
    );

endmodule
