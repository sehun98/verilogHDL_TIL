`timescale 1ns / 1ps

module dedecate_cpu (
    input wire clk,
    input wire rst_n,
    output wire [7:0] a_out
);

    wire w_a_eq_9;
    wire w_a_src_sel_1;
    wire w_a_src_sel_2;
    wire w_a_reg_load_1;
    wire w_a_reg_load_2;
    wire w_a_out_sel;

    control_unit u1_control_unit (
        .clk  (clk),
        .rst_n(rst_n),

        .a_eq_9    (w_a_eq_9),
        .a_src_sel_1 (w_a_src_sel_1),
        .a_src_sel_2 (w_a_src_sel_2),
        .a_reg_load_1(w_a_reg_load_1),
        .a_reg_load_2(w_a_reg_load_2),
        .a_out_sel (w_a_out_sel)
    );

    datapath u2_datapath (
        .clk  (clk),
        .rst_n(rst_n),

        .a_eq_9    (w_a_eq_9),
        .a_src_sel_1 (w_a_src_sel_1),
        .a_src_sel_2 (w_a_src_sel_2),
        .a_reg_load_1(w_a_reg_load_1),
        .a_reg_load_2(w_a_reg_load_2),
        .a_out_sel (w_a_out_sel),

        .a_out(a_out)
    );
endmodule
