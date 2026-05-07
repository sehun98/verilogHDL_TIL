`timescale 1ns / 1ps

module adder_sv (
    input  logic [7:0] a,
    input  logic [7:0] b,
    input  logic       mode,  // 0 : sum, 1 : sub
    output logic [7:0] sum,
    output logic       carry
);
    assign {carry, sum} = mode ? a - b : a + b;
endmodule


