`timescale 1ns / 1ps

module data_path (
    input wire clk,
    input wire rst_n,
    input wire run,
    input wire clear,
    input wire mode,
    output wire [13:0] tick_count
    );

    wire w_tick_10hz;

    assign reg_tick_10hz = w_tick_10hz & run;

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
        .clear(clear),
        .mode(mode),
        .tick(reg_tick_10hz),
        .tick_count(tick_count)
    );

endmodule
