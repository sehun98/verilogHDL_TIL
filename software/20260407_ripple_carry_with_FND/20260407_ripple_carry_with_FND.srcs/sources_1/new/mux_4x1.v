`timescale 1ns / 1ps

module mux_4x1(
    input wire [3:0] digit_ones,
    input wire [3:0] digit_tens,
    input wire [3:0] digit_hundreds,
    input wire [3:0] digit_thousands,
    input wire [1:0] digit_sel,
    output reg [3:0] digit_out
);

    always @(*) begin
        case (digit_sel)
            2'b00 : digit_out = digit_ones;
            2'b01 : digit_out = digit_tens;
            2'b10 : digit_out = digit_hundreds;
            2'b11 : digit_out = digit_thousands;
            default: digit_out = digit_ones;
        endcase
    end

endmodule
