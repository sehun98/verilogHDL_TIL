`timescale 1ns / 1ps

module tb_counter_4;
    reg clk;
    reg rst_n;
    wire [1:0] digit_sel;

    wire w_tick_1ms;

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
        .tick_1ms(w_tick_1ms)
    );

    counter_4 u2_counter_4 (
        .clk(w_tick_1ms),
        .rst_n(rst_n),
        .digit_sel(digit_sel)
    );
endmodule
