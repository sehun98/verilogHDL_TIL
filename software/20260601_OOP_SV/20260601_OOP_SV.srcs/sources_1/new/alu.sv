`timescale 1ns / 1ps

module alu (
    input wire opcode,
    input wire [7:0] a,
    input wire [7:0] b,
    output wire [7:0] result
);
    reg [7:0] result_reg;

    assign result = result_reg;
    always_comb begin
        case (opcode)
            1'b0: result_reg = a + b;
            1'b1: result_reg = a - b;
            default: result_reg = 8'd0;
        endcase
    end

endmodule
