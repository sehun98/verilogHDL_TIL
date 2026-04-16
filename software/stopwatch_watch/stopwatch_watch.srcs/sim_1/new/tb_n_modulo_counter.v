`timescale 1ns / 1ps

module tb_n_modulo_counter;
    reg clk;
    reg rst_n;
    wire [6:0] count;
    wire tick;

    wire w_tick_100hz;
    
    tick_gen_100hz #(
        .CLOCK_FREQ_HZ(100_000_000),
        .COUNT_HZ(100)
    ) u1_tick_gen_100hz (
        .clk(clk),
        .rst_n(rst_n),
        .tick_100hz(w_tick_100hz)
    );

    n_modulo_counter #(
        .N(100)
    ) u2_msec (
        .clk(clk),
        .rst_n(rst_n),
        .en(w_tick_100hz),
        .count(count),
        .tick(tick)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst_n = 0;
        repeat(2) @(posedge clk);
        rst_n = 1;

        #100_000_000;

    end

endmodule
