`timescale 1ns / 1ps
// todo value modify
module digit_splitter_1to4 #(
    parameter DATA_BIT = 6
) (
    input  wire [DATA_BIT-1:0] digit_data,
    output wire [3:0] digit_ones,
    output wire [3:0] digit_tens,
    output wire [3:0] digit_hundreds,
    output wire [3:0] digit_thousands
);

    assign digit_ones = digit_data % 10;
    assign digit_tens = (digit_data / 10) % 10;
    assign digit_hundreds = (digit_data / 100) % 10;
    assign digit_thousands = (digit_data / 1000) % 10;
endmodule