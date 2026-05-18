`timescale 1ns / 1ps

module dedicate_cpu_Arithmetic_sequence (
    input wire clk,
    input wire rst_n,
    output wire [7:0] out
);
    wire w_A_src_sel;
    wire w_SUM_src_sel;
    wire w_ALU_src_sel;
    wire w_A_reg_load;
    wire w_SUM_reg_load;
    wire w_OUT_reg_load;
    wire w_A_gr_10;

    control_unit_Arithmetic_sequence u1_control_unit_Arithmetic_sequence (
        .clk  (clk),
        .rst_n(rst_n),
        .A_src_sel (w_A_src_sel),
        .SUM_src_sel (w_SUM_src_sel),
        .ALU_src_sel (w_ALU_src_sel),
        .A_reg_load(w_A_reg_load),
        .SUM_reg_load(w_SUM_reg_load),
        .OUT_reg_load (w_OUT_reg_load),
        .A_gr_10(w_A_gr_10)
    );

    datapath_Arithmetic_sequence u2_datapath_Arithmetic_sequence (
        .clk  (clk),
        .rst_n(rst_n),
        .A_src_sel (w_A_src_sel),
        .SUM_src_sel (w_SUM_src_sel),
        .ALU_src_sel (w_ALU_src_sel),
        .A_reg_load(w_A_reg_load),
        .SUM_reg_load(w_SUM_reg_load),
        .OUT_reg_load (w_OUT_reg_load),
        .A_gr_10(w_A_gr_10),
        .out  (out)
    );

endmodule
