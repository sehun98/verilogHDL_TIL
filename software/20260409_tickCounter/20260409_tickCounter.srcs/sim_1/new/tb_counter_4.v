`timescale 1ns / 1ps


module tb_counter_4;
    reg clk;
    reg rst_n;
    wire [1:0] digit_sel;

counter_4 tb_counter_4 (
    .clk(clk),
    .rst_n(rst_n),
    .digit_sel(digit_sel)
);

initial begin
    {clk, rst_n} = 2'b00;
    #10 rst_n = 1;
end

always #5 clk = ~clk;

endmodule
