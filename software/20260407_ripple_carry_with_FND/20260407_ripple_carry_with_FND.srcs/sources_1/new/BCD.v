`timescale 1ns / 1ps

// 0~9
module BCD(
    input wire [3:0] data_in,
    output reg [0:7] seg
    );

always@(*) begin
    case (data_in)
        4'd0 : seg = 8'hC0;
        4'd1 : seg = 8'hF9;
        4'd2 : seg = 8'hA4;
        4'd3 : seg = 8'hB0;
        4'd4 : seg = 8'h99;
        4'd5 : seg = 8'h92;
        4'd6 : seg = 8'h82;
        4'd7 : seg = 8'hF8;
        4'd8 : seg = 8'h80;
        4'd9 : seg = 8'h90;
        4'd10 : seg = 8'h88;
        4'd11 : seg = 8'h83;
        4'd12 : seg = 8'hC6;
        4'd13 : seg = 8'hA1;
        4'd14 : seg = 8'h86;
        4'd15 : seg = 8'h8E;
        default: seg = 8'hFF;
    endcase
end

endmodule
