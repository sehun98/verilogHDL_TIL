`timescale 1ns / 1ps

// accumulator
module tb_square_wave_generator;
    reg  clk;
    reg  rst_n;
    wire square_wave_1ms_toggle;

    initial begin
        {clk, rst_n} = 2'b00;
        #10 rst_n = 1;
    end

    always #5 clk = ~clk;

    square_wave_generator u1_square_wave_generator (
        .clk(clk),
        .rst_n(rst_n),
        .square_wave_1ms_toggle(square_wave_1ms_toggle)
    );
endmodule
