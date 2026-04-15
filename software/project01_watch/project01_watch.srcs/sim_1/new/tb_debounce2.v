`timescale 1ns / 1ps
// stop watch watch
// run stop clear setting
// 기본 기능 + 추가 기능

module tb_debounce2 ();

    reg clk, rst, i_btn;
    wire o_btn;

    debounce2 dut (
        .clk   (clk),
        .rst_n   (rst),
        .din (i_btn),
        .dout (o_btn)
    );

    always #5 clk = ~clk;

    initial begin
        clk   = 0;
        rst   = 0;
        i_btn = 0;

        repeat (3) @(negedge clk);
        rst = 1;

        #10;
        i_btn = 1;
        repeat (8000) @(negedge clk);
        i_btn = 0;

        #20;
        $stop;
    end

endmodule
