`timescale 1ns / 1ps

module tb_decoder_2x4;
    reg [1:0] digit_sel;
    wire [3:0] digit;

    integer i = 0;

    initial begin
        for (i = 0; i < 4; i = i + 1) begin
            digit_sel = i; #10;
        end
    end

    decoder_2x4 u1_decoder_2x4 (
        .digit_sel(digit_sel),
        .digit(digit)
    );

endmodule
