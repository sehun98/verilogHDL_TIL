`timescale 1ns / 1ps

module tb_top_8bit_adder;
    reg        clk;
    reg        rst_n;
    reg  [7:0] a;
    reg  [7:0] b;

    wire [7:0] seg;
    wire       c_out;
    wire [3:0] digit;

    top_8bit_adder u1_top_8bit_adder (
        .sysclk(clk),
        .rst_n(rst_n),
        .a(a),
        .b(b),
        .seg(seg),
        .c_out(c_out),
        .digit(digit)
    );

    initial begin
        {clk, rst_n} = 2'b00;
        #10 rst_n = 1;
    end

    always #5 clk = ~clk;

    integer i, j;

    initial begin
        for (i = 0; i < 256; i = i + 1) begin
            for (j = 0; j < 256; j = j + 1) begin
                a = i;
                b = j;
                #1000;
            end
        end
    end

endmodule
