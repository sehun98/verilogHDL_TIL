`timescale 1ns / 1ps

module tb_tick_counter;
    reg clk;
    reg rst_n;
    reg tick;
    wire [13:0] tick_count;

    tick_counter #(
        .TICK_COUNT(10000)
    ) u1_tick_counter (
        .clk(clk),
        .rst_n(rst_n),
        .tick(tick),
        .tick_count(tick_count)
    );

    always #5 clk = ~clk;

    initial begin
        {clk, rst_n, tick} = 3'b000;
        #10 rst_n = 1;
    end

    initial begin
        
        
        
        #500_000_000; // 500ms

        $finish;
    end
endmodule
