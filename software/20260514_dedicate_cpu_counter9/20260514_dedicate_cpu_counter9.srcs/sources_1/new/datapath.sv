`timescale 1ns / 1ps

module datapath (
    input wire clk,
    input wire rst_n,

    input wire src_sel,
    input wire load,
    input wire out_sel,

    output wire eq_out,
    output wire [7:0] out
);

wire [7:0] w_alu_out;
wire [7:0] w_mux_out;
wire [7:0] w_reg_out;

mux2to1 u1_mux2to1 (
    .in1(8'd0),
    .in2(w_alu_out),
    .sel(src_sel),
    .out(w_mux_out)
);
register u2_register (
    .clk(clk),
    .rst_n(rst_n),
    .load(load),
    .din(w_mux_out),
    .dout(w_reg_out)
);

comparator u3_comparator (
    .in(w_alu_out),
    .comparate(8'd9),
    .eq_out(eq_out)
);

alu u4_alu (
    .a(w_reg_out),
    .b(8'd1),
    .alu_out(w_alu_out)
);
assign out = out_sel ? w_reg_out : 8'hzz;
endmodule

module mux2to1 (
    input wire [7:0] in1,
    input wire [7:0] in2,
    input wire sel,
    input wire [7:0] out
);
    assign out = (sel==0) ? in1 : in2;
endmodule

module register (
    input wire clk,
    input wire rst_n,
    input wire load,
    input wire [7:0] din,
    output reg [7:0] dout
);
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dout <= 8'd0;
        end else begin
            if (load) begin
                dout <= din;
            end
        end
    end
endmodule

module comparator (
    input wire [7:0] in,
    input wire [7:0] comparate,
    output wire eq_out
);
    assign eq_out = (in == comparate);
endmodule

module alu (
    input  wire [7:0] a,
    input  wire [7:0] b,
    output wire [7:0] alu_out
);
    assign alu_out = a + b;
endmodule

