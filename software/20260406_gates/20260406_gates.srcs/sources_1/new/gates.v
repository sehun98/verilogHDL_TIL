`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/04/06 10:54:52
// Design Name: 
// Module Name: gates
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


module gates(
    input wire a,
    input wire b,
    output wire [6:0] y
    );

    assign y[0] = a & b;
    assign y[1] = ~(a & b);
    assign y[2] = a | b;
    assign y[3] = ~(a | b);
    assign y[4] = a ^ b;
    assign y[5] = ~(a ^ b);    
    assign y[6] = ~a;
endmodule
