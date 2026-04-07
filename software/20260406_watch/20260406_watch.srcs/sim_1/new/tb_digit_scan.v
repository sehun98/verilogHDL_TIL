`timescale 1ns / 1ps

module tb_digit_scan;
    reg [1:0] digit_sel;
    wire [3:0] digit;

digit_scan u1_digit_scan(
    .digit_sel(digit_sel),
    .digit(digit)
    );


initial begin
    digit_sel = 2'b00; #10;
    digit_sel = 2'b01; #10;
    digit_sel = 2'b10; #10;
    digit_sel = 2'b11; #10;
end

endmodule
