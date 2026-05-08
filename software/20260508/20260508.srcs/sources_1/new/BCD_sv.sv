`timescale 1ns / 1ps

module BCD_sv (
    input  logic [3:0] data,
    output logic [7:0] seg
);

    always @(*) begin
        case (data)
            4'd0: seg = 8'b1100_0000;
            4'd1: seg = 8'b1111_1001;
            4'd2: seg = 8'b1010_0100;
            4'd3: seg = 8'b1011_0000;
            4'd4: seg = 8'b1001_1001;
            4'd5: seg = 8'b1001_0010;
            4'd6: seg = 8'b1000_0011;
            4'd7: seg = 8'b1111_1000;
            4'd8: seg = 8'b1000_0000;
            4'd9: seg = 8'b1001_1000;
            4'd10: seg = 8'b1111_1111;
            4'd11: seg = 8'b1111_1111;
            4'd12: seg = 8'b1111_1111;
            4'd13: seg = 8'b1111_1111;
            4'd14: seg = 8'b1111_1111;
            4'd15: seg = 8'b1111_1111;
            default: seg = 8'b1111_1111;
        endcase
    end
endmodule
