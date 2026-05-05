`timescale 1ns / 1ps

// 0~99
module digit_splitter_2(
    input wire [6:0] i_data,
    output wire [3:0] o_digit_1,
    output wire [3:0] o_digit_10
    );

    assign o_digit_1 = i_data % 10;
    assign o_digit_10 = i_data / 10;
endmodule
