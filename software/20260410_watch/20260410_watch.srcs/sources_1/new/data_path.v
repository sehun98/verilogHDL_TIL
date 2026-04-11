`timescale 1ns / 1ps

module data_path (
    input wire clk,
    input wire rst_n,
    input wire stop,
    input wire reset,
    input wire mode_sel,
    output wire [13:0] tick_count
    );

    wire w_tick_10hz;

    wire w_clk;
    wire w_rst_n;

    assign w_clk = clk & stop;
    assign w_rst_n = rst_n & ~reset;

    clk_tick_gen_10hz u1_clk_tick_gen_10hz (
        .clk(w_clk),
        .rst_n(w_rst_n),
        .tick_10hz(w_tick_10hz)
    );

    tick_counter #(
        .TICK_COUNT(10000)
    ) u2_tick_counter (
        .clk(clk),
        .rst_n(w_rst_n),
        .mode_sel(mode_sel),
        .tick(w_tick_10hz),
        .tick_count(tick_count)
    );

endmodule
