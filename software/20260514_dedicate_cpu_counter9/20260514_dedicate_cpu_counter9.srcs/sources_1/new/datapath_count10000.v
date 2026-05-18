`timescale 1ns / 1ps

module datapath_count10000(
    input wire clk,
    input wire rst_n,

    input wire clear,
    input wire load,
    input wire out_sel,
    input wire mode,

    output wire eq_0_out,
    output wire eq_99_out,
    output wire [7:0] out
);

wire [7:0] w_alu_out_1;
wire [7:0] w_mux_out_1;
wire [7:0] w_reg_out;

wire [7:0] w_alu_out_2;
wire [7:0] w_mux_out_2;
wire [7:0] w_mux_out_3;

mux2to1 u1_mux2to1 (
    .in1(w_alu_out_1),
    .in2(w_alu_out_2),
    .sel(mode),
    .out(w_mux_out_1)
);

mux2to1 u2_mux2to1 (
    .in1(8'd0),
    .in2(w_mux_out_1),
    .sel(clear),
    .out(w_mux_out_2)
);

register u3_register (
    .clk(clk),
    .rst_n(rst_n),
    .load(run),
    .din(w_mux_out_2),
    .dout(w_reg_out)
);

comparator u4_comparator (
    .in(w_alu_out_1),
    .comparate(8'd99),
    .eq_out(eq_99_out)
);

comparator u5_comparator (
    .in(w_alu_out_2),
    .comparate(8'd0),
    .eq_out(eq_0_out)
);

alu u6_alu (
    .a(w_alu_out_2),
    .b(8'd1),
    .alu_out(w_alu_out_2)
);

alu u7_alu (
    .a(w_alu_out_2),
    .b(8'd1),
    .alu_out(w_alu_out_1)
);

mux2to1 u8_mux2to1 (
    .in1(w_alu_out_1),
    .in2(w_alu_out_2),
    .sel(mode),
    .out(w_mux_out_3)
);
assign out = out_sel ? w_mux_out_3 : 8'hzz;
endmodule
