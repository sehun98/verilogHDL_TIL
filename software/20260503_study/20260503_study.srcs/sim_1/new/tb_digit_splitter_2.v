`timescale 1ns / 1ps

module tb_digit_splitter_2;
    reg  [6:0] i_data;
    wire [3:0] o_digit_1;
    wire [3:0] o_digit_10;

    digit_splitter_2 u1_digit_splitter_2 (
        .i_data(i_data),
        .o_digit_1(o_digit_1),
        .o_digit_10(o_digit_10)
    );

    integer i;
    initial begin
        #100;
        for (i = 0; i < 100; i = i + 1) begin
            i_data = i;
            #10;
        end
        #100;
        $finish;
    end

endmodule
