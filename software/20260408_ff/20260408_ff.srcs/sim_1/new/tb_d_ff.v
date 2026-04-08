`timescale 1ns / 1ps

module tb_d_ff;
reg clk;
reg rst_n;
reg d;
wire q;

initial begin
    {clk, rst_n, d} = 3'b000;
    #10 rst_n = 1;
end

always #5 clk = ~clk;

initial begin
    d = 0; #10;
    d = 1; #10;
    d = 0; #10;
end

d_ff u1_d_ff (
    .clk(clk),
    .rst_n(rst_n),
    .d(d),
    .q(q)
);
endmodule
