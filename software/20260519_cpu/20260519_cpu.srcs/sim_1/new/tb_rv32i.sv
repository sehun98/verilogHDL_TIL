`timescale 1ns / 1ps


module tb_rv32i( );
    logic clk, rst_n;
    top_rv32i_soc dut(.*);


always #5 clk = ~clk;

initial begin
    clk = 0;
    rst_n = 0;
    @(negedge clk);
    @(negedge clk);

    rst_n = 1;

    @(negedge clk);
    @(negedge clk);
   

    $stop;
end
endmodule