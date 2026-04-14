`timescale 1ns / 1ps

module counter_10000 (
    input wire clk,
    input wire rst_n,
    input wire btn_run,
    input wire btn_clear,
    input wire btn_mode,
    output wire [3:0] digit,
    output wire [7:0] seg
);

    wire [13:0] w_tick_count;
    
    wire w_btn_run;
    wire w_btn_clear;
    wire w_btn_mode;

    wire w_run;
    wire w_clear;
    wire w_mode;

    data_path u1_data_path (
        .clk(clk),
        .rst_n(rst_n),
        .run(w_run),
        .clear(w_clear),
        .mode(w_mode),
        .tick_count(w_tick_count)
    );

    FND_Controller u2_FND_Controller (
        .clk  (clk),
        .rst_n(rst_n),
        .data (w_tick_count),
        .digit(digit),
        .seg  (seg)
    );

    control_unit u3_control_unit (
        .clk(clk),
        .rst_n(rst_n),
        .btn_run(w_btn_run),
        .btn_clear(w_btn_clear),
        .btn_mode(w_btn_mode),
        .run(w_run),
        .clear(w_clear),
        .mode(w_mode)
    );

    btn_interface u4_btn_interface (
        .clk(clk),
        .rst_n(rst_n),
        .btn_in(btn_run),
        .btn_pulse(w_btn_run)
    );

    btn_interface u5_btn_interface (
        .clk(clk),
        .rst_n(rst_n),
        .btn_in(btn_clear),
        .btn_pulse(w_btn_clear)
    );
    
    btn_interface u6_btn_interface (
        .clk(clk),
        .rst_n(rst_n),
        .btn_in(btn_mode),
        .btn_pulse(w_btn_mode)
    );

endmodule
