`timescale 1ns / 1ps

module tb_baudrate ();
    logic clk;
    logic rst_n;
    logic [2:0] BR;
    logic tick;

    baudrate dut (
        .clk(clk),
        .rst_n(rst_n),
        .BR(BR),
        .tick(tick)
    );
    integer i;

    always #5 clk = ~clk;

    initial begin
        clk   = 0;
        rst_n = 0;
        BR = 0;
        repeat (2) @(posedge clk);
        rst_n = 1;

        for (i = 0; i < 8; i++) begin
            BR = i;
            #1000_0;
        end

    end
endmodule
