`timescale 1ns / 1ps

module tb_flip_flop;
    reg  clk;
    reg  rst_n;
    reg  d;
    wire q;

    flip_flop u1_flip_flop (
        .clk(clk),
        .rst_n(rst_n),
        .d(d),
        .q(q)
    );

    initial begin
        {clk, rst_n, d} = 3'b000; 
        #10 rst_n = 1;
    end
    always #5 clk = ~clk;

    initial begin
        d = 1;
        #100;
        d = 0;
        #100;
        d = 1;
        #100;
        d = 0;
        #100;
    end


endmodule
