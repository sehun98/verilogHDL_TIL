`timescale 1ns / 1ps

module tb_clk_tick_gen_10hz;
    reg clk;
    reg rst_n;
    wire  tick_10hz;

clk_tick_gen_10hz u1_clk_tick_gen_10hz (
    .clk(clk),
    .rst_n(rst_n),
    .tick_10hz(tick_10hz)
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
