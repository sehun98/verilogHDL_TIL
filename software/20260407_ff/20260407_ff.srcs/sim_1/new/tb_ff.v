`timescale 1ns / 1ps

module tb_ff;

    reg clk;
    reg d;
    wire q;


    initial begin
        {clk,d} = 0;
    end

    always #5 clk = ~clk;

    initial begin
        #10 d = 1;
        #10 d = 0;
        #10 $finish();
    end

ff dut(
    .clk(clk),
    .d(d),
    .q(q)
    );
endmodule
