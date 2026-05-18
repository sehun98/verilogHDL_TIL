`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/05/14 19:50:26
// Design Name: 
// Module Name: tb_dedicate_cpu
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tb_dedicate_cpu();
logic clk;
logic rst_n;
logic [7:0] out;

dedicate_cpu dut (
    .clk(clk),
    .rst_n(rst_n),
    .out(out)
);

always #5 clk = ~clk;

initial begin
    clk = 0;
    rst_n = 0;
    repeat(2) @(posedge clk);
    rst_n = 1;
    #1000;
    $finish;
end

endmodule
