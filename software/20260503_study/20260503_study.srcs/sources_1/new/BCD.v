`timescale 1ns / 1ps

module BCD (
    input  wire [3:0] i_data,
    output reg [7:0] o_fnd_decode
);
    // 0~15

    always @(*) begin
        case (i_data)
            4'd0: o_fnd_decode = 8'b1100_0000;
            4'd1: o_fnd_decode = 8'b1111_1001;
            4'd2: o_fnd_decode = 8'b1010_0100;
            4'd3: o_fnd_decode = 8'b1011_0000;
            4'd4: o_fnd_decode = 8'b1001_1001;
            4'd5: o_fnd_decode = 8'b1001_0010;
            4'd6: o_fnd_decode = 8'b1000_0010;
            4'd7: o_fnd_decode = 8'b1111_1000;
            4'd8: o_fnd_decode = 8'b1000_0000;
            4'd9: o_fnd_decode = 8'b1001_0000;
            4'd10: o_fnd_decode = 8'b1000_1000;  // A
            4'd11: o_fnd_decode = 8'b1000_0011;  // b
            4'd12: o_fnd_decode = 8'b1100_0110;  // C
            4'd13: o_fnd_decode = 8'b1010_0001;  // d
            4'd14: o_fnd_decode = 8'b1000_0110;  // E
            4'd15: o_fnd_decode = 8'b1000_1110;  // F
            default: o_fnd_decode = 8'b1111_1111;
        endcase
    end
endmodule


























