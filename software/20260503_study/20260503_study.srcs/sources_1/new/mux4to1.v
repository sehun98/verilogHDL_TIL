`timescale 1ns / 1ps

module mux4to1 (
    input  wire [1:0] i_digit_sel,
    input  wire [3:0] i_digit_1,
    input  wire [3:0] i_digit_10,
    input  wire [3:0] i_digit_100,
    input  wire [3:0] i_digit_1000,
    output reg [3:0] o_digit_out
);

    always @(*) begin
        case (i_digit_sel)
            2'b00:   o_digit_out = i_digit_1;
            2'b01:   o_digit_out = i_digit_10;
            2'b10:   o_digit_out = i_digit_100;
            2'b11:   o_digit_out = i_digit_1000;
            default: o_digit_out = i_digit_1;
        endcase
    end
endmodule
