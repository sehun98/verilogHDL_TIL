`timescale 1ns / 1ps

module ff(
    input wire clk,
    input wire d,
    output reg q
    );

    always @(posedge clk) begin
        q <= d;
    end
    
endmodule
