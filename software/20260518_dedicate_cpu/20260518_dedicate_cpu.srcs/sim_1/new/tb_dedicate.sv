`timescale 1ns / 1ps

module tb_dedicate();

    reg clk;
    reg rst_n;

    wire [7:0] out;

    dedicate dut (
        .clk  (clk),
        .rst_n(rst_n),
        .out  (out)
    );

    // clock generation
    always #5 clk = ~clk;

    // monitor
    initial begin
        $display("TIME\tSTATE_OUT");
        $monitor("[%0t] out = %0d", $time, out);
    end

    // stimulus
    initial begin
        clk   = 0;
        rst_n = 0;

        #20;
        rst_n = 1;

        #500;

        $finish;
    end

endmodule