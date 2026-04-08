`timescale 1ns / 1ps

module seg_mux (
    input  wire [6:0] digit_ones,
    input  wire [6:0] digit_tens,
    input  wire [6:0] digit_hundreds,
    input  wire [6:0] digit_thousands,
    input  wire [1:0] data_sel,
    output reg  [6:0] seg
);

    always @(*) begin
        case (data_sel)
            2'b00: seg = digit_ones;
            2'b01: seg = digit_tens;
            2'b10: seg = digit_hundreds;
            2'b11: seg = digit_thousands;
        endcase
    end

endmodule
