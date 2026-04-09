`timescale 1ns / 1ps

module tb_square_wave_generator;
    reg  clk;
    reg  rst_n;
    wire tick_1ms;

    initial begin
        {clk, rst_n} = 2'b00;
        #10 rst_n = 1;
    end

    always #5 clk = ~clk;

    square_wave_generator u1_square_wave_generator (
        .clk(clk),
        .rst_n(rst_n),
        .tick_1ms(tick_1ms)
    );
endmodule
