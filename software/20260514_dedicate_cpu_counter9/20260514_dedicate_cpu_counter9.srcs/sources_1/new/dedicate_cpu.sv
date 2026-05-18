`timescale 1ns / 1ps

module dedicate_cpu (
    input wire clk,
    input wire rst_n,
    output wire [7:0] out
);
    wire src_sel;
    wire load;
    wire out_sel;
    wire eq_out;

    datapath u1_datapath (
        .clk(clk),
        .rst_n(rst_n),

        .src_sel(src_sel),
        .load(load),
        .out_sel(out_sel),
        .eq_out(eq_out),
        
        .out(out)
    );

control_unit u2_control_unit (
    .clk(clk),
    .rst_n(rst_n),
    .src_sel(src_sel),
    .load(load),
    .out_sel(out_sel),
    .eq_out(eq_out)
);

endmodule
