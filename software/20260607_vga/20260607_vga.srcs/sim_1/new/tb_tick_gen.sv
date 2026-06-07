`timescale 1ns / 1ps

module tb_tick_gen ();
    logic clk;
    logic rst_n;
    logic tick;

    tick_gen #(
        .CLOCK_FREQ_HZ(100_000_000),
        .COUNT(800 * 525 * 60)
    ) dut (
        .clk  (clk),
        .rst_n(rst_n),
        .tick (tick)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst_n = 0;
        repeat(2) @(posedge clk);
        rst_n = 1;

        repeat(10) #100_000_000;
        $finish();
    end

endmodule
