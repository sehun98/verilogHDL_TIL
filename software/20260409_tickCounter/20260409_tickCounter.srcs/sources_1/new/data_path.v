`timescale 1ns / 1ps

module data_path (
    input wire clk,
    input wire rst_n,
    output wire [13:0] tick_count
    );

    wire w_tick_10hz;

    clk_tick_gen_10hz u1_clk_tick_gen_10hz (
        .clk(clk),
        .rst_n(rst_n),
        .tick_10hz(w_tick_10hz)
    );

    tick_counter #(
        .TICK_COUNT(10000)
    ) u2_tick_counter (
        .clk(clk),
        .rst_n(rst_n),
        .tick(w_tick_10hz),
        .tick_count(tick_count)
    );

endmodule
