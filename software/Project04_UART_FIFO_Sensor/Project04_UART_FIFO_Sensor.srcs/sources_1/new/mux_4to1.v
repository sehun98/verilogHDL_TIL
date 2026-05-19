`timescale 1ns / 1ps

module mux_4to1(
    input wire [3:0] digit_1,
    input wire [3:0] digit_2,
    input wire [3:0] digit_3,
    input wire [3:0] digit_4,

    input wire [2:0] digit_sel,
    output reg [3:0] digit_out
);

    always @(*) begin
        case (digit_sel)
            3'b000 : digit_out = digit_1;
            3'b001 : digit_out = digit_2;
            3'b010 : digit_out = digit_3;
            3'b011 : digit_out = digit_4;
            3'b100 : digit_out = digit_1;
            3'b101 : digit_out = digit_2;
            3'b110 : digit_out = digit_3;
            3'b111 : digit_out = digit_4;
            default: digit_out = digit_1;
        endcase
    end
endmodule
