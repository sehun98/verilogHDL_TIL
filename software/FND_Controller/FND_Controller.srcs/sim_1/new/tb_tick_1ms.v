`timescale 1ns / 1ps

module tb_tick_1ms;
    reg  clk;
    reg  rst_n;
    wire tick_1ms;

    initial begin
        {clk, rst_n} = 2'b00;
        #10 rst_n = 1;
    end

    always #5 clk = ~clk;

    tick_1ms #(
        .CLOCK_FREQ_HZ(100_000_000),
        .TICK_HZ(1000)
    ) u1_tick_1ms (
        .clk(clk),
        .rst_n(rst_n),
        .tick_1ms(tick_1ms)
    );
endmodule
