`timescale 1ns / 1ps

module tb_sck_gen ();
    logic clk;
    logic rst_n;
    logic sck;

    sck_gen#(
        .CLOCK_FREQ_HZ(100_000_000),
        .BAUD_RATE(500_000)
    ) dut (
        .clk(clk), .rst_n(rst_n), .sck(sck)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst_n = 0;
        repeat(2) @(posedge clk);
        rst_n = 1;
    end

endmodule
