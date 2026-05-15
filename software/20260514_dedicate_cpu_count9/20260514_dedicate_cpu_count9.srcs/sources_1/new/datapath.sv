`timescale 1ns / 1ps

module datapath (
    input wire clk,
    input wire rst_n,

    input wire a_src_sel,
    input wire a_reg_load,
    output wire a_eq_9,
    input wire a_out_sel,
    output wire [7:0] a_out
);
    wire [7:0] w_alu_out;
    wire [7:0] w_mux_out;
    reg  [7:0] w_reg_out;

    // 1. mux
    mux2to1 u1_mux2to1 (
        .in0(8'd0),
        .in1(w_alu_out),
        .sel(a_src_sel),
        .mux_out(w_mux_out)
    );

    // 2. reg
    a_reg u2_a_reg (
        .clk(clk),
        .rst_n(rst_n),
        .load(a_reg_load),
        .data_in(w_mux_out),
        .data_out(w_reg_out)
    );

    //3. alu
    alu u3_alu (
        .a(w_reg_out),
        .b(8'd1),
        .alu_out(w_alu_out)
    );

    // 4. comparator
    compare_eq u3_compare_eq (
        .in(w_reg_out),
        .compare(8'd8),
        .eq_out(a_eq_9)
    );

    // 5. tri state buff
    assign a_out = (a_out_sel) ? w_reg_out : 8'hzz;

endmodule
/*
module mux2to1 (
    input logic [7:0] in0,
    input logic [7:0] in1,
    input logic sel,
    output logic [7:0] mux_out
);
    assign mux_out = (!sel) ? in0 : in1;
endmodule

module a_reg (
    input logic clk,
    input logic rst_n,
    input logic load,
    input logic [7:0] data_in,
    output logic [7:0] data_out
);
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 8'd0;
        end else begin
            if (load) begin
                data_out <= data_in;
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
    assign eq_out = (in == compare) ? 1'b1 : 1'b0;
endmodule


*/