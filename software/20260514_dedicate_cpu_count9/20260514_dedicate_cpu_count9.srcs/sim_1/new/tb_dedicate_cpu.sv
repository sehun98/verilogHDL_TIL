`timescale 1ns / 1ps

module tb_dedicate_cpu();
    reg clk;
    reg rst_n;
    reg [7:0] a_out;

dedecate_cpu dut (.*);

always #5 clk = ~clk;

initial begin
    clk = 0;
    rst_n = 0;
    repeat(2) @(posedge clk);
    rst_n = 1;

    #1000;
    $finish;
end

endmodule
