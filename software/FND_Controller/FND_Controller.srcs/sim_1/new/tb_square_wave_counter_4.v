`timescale 1ns / 1ps

module tb_square_wave_counter_4;
    reg clk;
    reg rst_n;
    wire [1:0] digit_sel;

    wire w_tick_1ms;

    initial begin
        {clk, rst_n} = 2'b00;
        #10 rst_n = 1;
    end

    always #5 clk = ~clk;

    square_wave_generator u1_square_wave_generator (
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
