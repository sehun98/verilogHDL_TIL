`timescale 1ns / 1ps

module tb_counter_10000;
    reg clk;
    reg rst_n;
    wire [3:0] digit;
    wire [7:0] seg;

    counter_10000 u1_counter_10000 (
        .clk  (clk),
        .rst_n(rst_n),
        .digit(digit),
        .seg  (seg)
    );

    always #5 clk = ~clk;
    
    initial begin
        {clk, rst_n} = 2'b00;
        #10 rst_n = 1;
    end

    initial begin
        #300_000_000 $finish;
    end

endmodule
