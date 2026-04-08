`timescale 1ns / 1ps

// accumulator
module tb_tick_generator;
    reg  clk;
    reg  rst_n;
    wire tick_1ms;

    initial begin
        {clk, rst_n} = 2'b00;
        #10 rst_n = 1;
    end

    always #5 clk = ~clk;

    tick_generator #(
        .CLOCK_FREQ_HZ(100_000_000),
        .TICK_HZ(1000)
    ) u1_tick_generator (
        .clk(clk),
        .rst_n(rst_n),
        .tick_1ms(tick_1ms)
    );
endmodule
