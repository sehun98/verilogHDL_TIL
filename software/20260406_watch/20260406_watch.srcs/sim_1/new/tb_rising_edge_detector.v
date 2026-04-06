`timescale 1ns / 1ps

module tb_rising_edge_detector;
reg clk;
reg rst_n;
reg level_in;
wire pulse_out;

initial begin
    {clk, rst_n, level_in} = 3'b000;
    #10 rst_n = 1'b1;
end

always #5 clk = ~clk;

initial begin
    #1000;
    level_in = 1;
    #1000;
    level_in = 0;
    #1000;
    level_in = 1;
    #1000;
end

rising_edge_detector u1_rising_edge_detector(
    .clk(clk),
    .rst_n(rst_n),
    .level_in(level_in),
    .pulse_out(pulse_out)
);
endmodule
