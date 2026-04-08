`timescale 1ns / 1ps

module d_ff (
    input  wire clk,
    input  wire rst_n,
    input  wire d,
    output reg  q
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q <= 0;
        end else begin
            q <= d;
        end
    end
endmodule
