`timescale 1ns / 1ps

module tb_count;
    parameter N = 4;
    localparam N_WIDTH = $clog2(N);

    reg clk;
    reg rst_n;
    wire tick;
    wire [N_WIDTH-1:0] count;

    tick_gen_1000hz #(
        .CLOCK_FREQ_HZ(100_000_000),
        .HZ(1000)
    ) u1_tick_gen_1000hz (
        .clk  (clk),
        .rst_n(rst_n),
        .tick (tick)
    );

    count #(
        .N(N)
    ) u2_count (
        .clk  (clk),
        .rst_n(rst_n),
        .tick (tick),
        .count(count)
    );

    always #5 clk = ~clk;

    initial begin
        clk   = 0;
        rst_n = 0;
        repeat (5) @(posedge clk);
        rst_n = 1;

        #1000_000_0;

        $finish;
    end

endmodule
