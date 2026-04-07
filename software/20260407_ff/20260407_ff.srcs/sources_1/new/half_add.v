`timescale 1ns / 1ps

module half_add (
    input wire a,
    input wire b,
    input wire c_out,
    input wire sum
);
    assign sum   = a ^ b;
    assign c_out = a & b;
endmodule
