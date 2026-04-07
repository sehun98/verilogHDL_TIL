`timescale 1ns / 1ps

// 0~9
module BCD(
    input wire [3:0] data_in,
    output reg [6:0] seg
    );

always@(*) begin
    case (data_in)
        4'd0 : seg = 7'b1111_110;
        4'd1 : seg = 7'b0110_000;
        4'd2 : seg = 7'b1101_101;
        4'd3 : seg = 7'b1111_001;
        4'd4 : seg = 7'b0110_011;
        4'd5 : seg = 7'b1011_011;
        4'd6 : seg = 7'b0011_111;
        4'd7 : seg = 7'b1110_000;
        4'd8 : seg = 7'b1111_111;
        4'd9 : seg = 7'b1110_011;
        default: seg = 7'b1111_111;
    endcase
end

endmodule
