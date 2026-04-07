`timescale 1ns / 1ps


module digit_scan(
    input wire [1:0] digit_sel,
    output reg [3:0] digit
    );

    always@(*) begin
        case (digit_sel)
            2'b00 : digit = 4'b0001;
            2'b01 : digit = 4'b0010;
            2'b10 : digit = 4'b0100;
            2'b11 : digit = 4'b1000;
            default: digit = 4'b1111;
        endcase

    end
endmodule
