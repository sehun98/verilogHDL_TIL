`timescale 1ns / 1ps

module half_add (
    input wire a,
    input wire b,
    output wire c_out,
    output wire sum
);
    assign sum   = a ^ b;
    assign c_out = a & b;
endmodule
