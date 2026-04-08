`timescale 1ns / 1ps

module tb_digit_splitter;
    reg [7:0] sum_data;
    wire [3:0] digit_ones;
    wire [3:0] digit_tens;
    wire [3:0] digit_hundreds;
    wire [3:0] digit_thousands;

digit_splitter u1_digit_splitter (
    .sum_data(sum_data),
    .digit_ones(digit_ones),
    .digit_tens(digit_tens),
    .digit_hundreds(digit_hundreds),
    .digit_thousands(digit_thousands)
);

integer seed = 5;
integer i;

initial begin
    for(i=0;i<10;i=i+1) begin
        sum_data = $random(seed) % 3; #10;
    end
end

endmodule
