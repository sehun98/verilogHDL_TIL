`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/04/07 07:29:24
// Design Name: 
// Module Name: tb_n_modulo
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


module tb_n_modulo;
    parameter N = 1000;
    localparam M = $clog2(N);

    reg clk;
    reg rst_n;
    reg en;
    wire tick;
    wire [M-1:0] data_out;

    initial begin
        {clk, rst_n, en} = 3'b0;
        #10 rst_n = 1;
    end

    always #5 clk = ~clk;

    initial begin
        #1000_000 en = 1;
        #1000_000 en = 0;
        #1000_000;
        $stop;
    end


    n_modulo #(
        .N(N)
    ) u1_n_modulo (
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .tick(tick),
        .data_out(data_out)
    );
endmodule
