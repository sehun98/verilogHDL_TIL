`timescale 1ns / 1ps

module tb_tick_gen_1000hz;
    reg  clk;
    reg  rst_n;
    wire tick;

    tick_gen_1000hz #(
        .CLOCK_FREQ_HZ(100_000_000),
        .HZ(1000)
    ) u1_tick_gen_1000hz (
        .clk  (clk),
        .rst_n(rst_n),
        .tick (tick)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst_n = 0;
        repeat(5) @(posedge clk);
        rst_n = 1;

        #1000_000;
        $finish;
    end

endmodule
