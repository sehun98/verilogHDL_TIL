`timescale 1ns / 1ps

module tb_rv32i ();
    reg clk;
    reg rst_n;

    top_rv32i_soc dut (
        .clk  (clk),
        .rst_n(rst_n)
    );

    always #5 clk = ~clk;

    initial begin
        clk   = 0;
        rst_n = 0;
        repeat (2) @(posedge clk);
        rst_n = 1;

        #1000000;
        $finish();
    end

endmodule

