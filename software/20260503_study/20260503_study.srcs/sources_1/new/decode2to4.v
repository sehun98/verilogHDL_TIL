`timescale 1ns / 1ps
// 0~3
module decode2to4 (
    input  wire [1:0] count,
    output reg  [3:0] digit
);
    always @(*) begin
        case (count)
            2'd0: digit = 4'b1110;
            2'd1: digit = 4'b1100;
            2'd2: digit = 4'b1011;
            2'd3: digit = 4'b0111;
            default: digit = 4'b1110;
        endcase
    end
endmodule
