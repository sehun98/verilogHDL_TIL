`timescale 1ns / 1ps

module datapath_Arithmetic_sequence (
    input wire clk,
    input wire rst_n,

    input wire A_src_sel,
    input wire SUM_src_sel,
    input wire ALU_src_sel,

    input wire A_reg_load,
    input wire SUM_reg_load,
    input wire OUT_reg_load,

    output wire A_gr_10,
    output wire [7:0] out
);
    wire [7:0] w_A_mux_out;
    wire [7:0] w_SUM_mux_out;
    wire [7:0] w_ALU_mux_out;

    reg  [7:0] w_A_reg_out;
    reg  [7:0] w_SUM_reg_out;

    reg  [7:0] w_ALU_out;

    // 1. mux
    mux2to1 u1_A_mux2to1 (
        .in0(8'd0),
        .in1(w_ALU_out),
        .sel(A_src_sel),
        .mux_out(w_A_mux_out)
    );

    // 2. mux
    mux2to1 u2_SUM_mux2to1 (
        .in0(8'd0),
        .in1(w_ALU_out),
        .sel(SUM_src_sel),
        .mux_out(w_SUM_mux_out)
    );

    // 3. reg
    register u3_A_register (
        .clk(clk),
        .rst_n(rst_n),
        .load(A_reg_load),
        .data_in(w_A_mux_out),
        .data_out(w_A_reg_out)
    );

    // 4. reg
    register u4_SUM_register (
        .clk(clk),
        .rst_n(rst_n),
        .load(SUM_reg_load),
        .data_in(w_SUM_mux_out),
        .data_out(w_SUM_reg_out)
    );

    // 5. mux
    mux2to1 u5_A_SUM_mux2to1 (
        .in0(8'd1),
        .in1(w_SUM_reg_out),
        .sel(ALU_src_sel),
        .mux_out(w_ALU_mux_out)
    );

    //6. alu
    alu u6_alu (
        .a(w_A_reg_out),
        .b(w_ALU_mux_out),
        .alu_out(w_ALU_out)
    );

    // 7. comparator
    compare_eq u7_compare_eq (
        .in(w_A_reg_out),
        .compare(8'd9),
        .eq_out(A_gr_10)
    );

    // 8. reg
    register u8_OUT_register (
        .clk(clk),
        .rst_n(rst_n),
        .load(OUT_reg_load),
        .data_in(w_SUM_reg_out),
        .data_out(out)
    );
endmodule


module mux2to1 (
    input logic [7:0] in0,
    input logic [7:0] in1,
    input logic sel,
    output logic [7:0] mux_out
);
    assign mux_out = (sel==0) ? in0 : in1;
endmodule

module register (
    input logic clk,
    input logic rst_n,
    input logic load,
    input logic [7:0] data_in,
    output logic [7:0] data_out
);

    reg [7:0] register;

    assign data_out = register;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            register <= 8'd0;
        end else begin
            if (load) begin
                register <= data_in;
            end
        end
    end
endmodule

module alu (
    input  logic [7:0] a,
    input  logic [7:0] b,
    output logic [7:0] alu_out
);
    assign alu_out = a + b;
endmodule

module compare_eq (
    input  logic [7:0] in,
    input  logic [7:0] compare,
    output logic eq_out
);
    assign eq_out = (in > compare) ? 1'b1 : 1'b0;
endmodule


