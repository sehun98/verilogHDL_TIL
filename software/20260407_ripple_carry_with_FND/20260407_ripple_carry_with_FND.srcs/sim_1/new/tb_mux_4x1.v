`timescale 1ns / 1ps

module tb_mux_4x1;
    reg  [3:0] digit_ones;
    reg  [3:0] digit_tens;
    reg  [3:0] digit_hundreds;
    reg  [3:0] digit_thousands;
    reg  [1:0] digit_sel;
    wire [3:0] digit_out;

    integer i;

    initial begin
        digit_ones = 0;
        digit_tens = 1;
        digit_hundreds = 2;
        digit_thousands = 3;
    end

    initial begin
        for (i = 0; i < 4; i = i + 1) begin
            digit_sel = i; #10;
        end
    end


    mux_4x1 u1_mux_4x1 (
        .digit_ones(digit_ones),
        .digit_tens(digit_tens),
        .digit_hundreds(digit_hundreds),
        .digit_thousands(digit_thousands),
        .digit_sel(digit_sel),
        .digit_out(digit_out)
    );
endmodule
