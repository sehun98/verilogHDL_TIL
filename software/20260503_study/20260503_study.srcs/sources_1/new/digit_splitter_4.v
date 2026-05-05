`timescale 1ns / 1ps

// 0~9999
module digit_splitter_4(
    input wire [13:0] i_data,
    output wire [3:0] o_digit_1,
    output wire [3:0] o_digit_10,
    output wire [3:0] o_digit_100,
    output wire [3:0] o_digit_1000
    );

    assign o_digit_1 = i_data % 10;
    assign o_digit_10 = (i_data / 10) % 10;
    assign o_digit_100 = (i_data / 100) % 10;
    assign o_digit_1000 = i_data / 1000;
endmodule
