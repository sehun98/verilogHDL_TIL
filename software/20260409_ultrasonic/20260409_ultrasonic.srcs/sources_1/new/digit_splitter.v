`timescale 1ns / 1ps

module digit_splitter (
    input  wire [9:0] sum_data,

    output wire [3:0] digit_ones,
    output wire [3:0] digit_tens,
    output wire [3:0] digit_hundreds,
    output wire [3:0] digit_thousands
);

    assign digit_ones = sum_data % 10;
    assign digit_tens = (sum_data / 10) % 10;
    assign digit_hundreds = (sum_data / 100) % 10;
    assign digit_thousands = (sum_data / 1000) % 10;

endmodule