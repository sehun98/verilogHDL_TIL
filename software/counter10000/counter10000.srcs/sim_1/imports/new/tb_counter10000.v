`timescale 1ns / 1ps

module tb_counter10000 ();
    reg        clk;
    reg        rst_n;
    reg        btn_run;
    reg        btn_clear;
    reg        btn_mode;
    wire [3:0] digit;
    wire [7:0] seg;

    counter_10000 dut (
        .clk      (clk),
        .rst_n    (rst_n),
        .btn_run  (btn_run),
        .btn_clear(btn_clear),
        .btn_mode (btn_mode),
        .digit    (digit),
        .seg      (seg)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst_n = 0;
        btn_run = 0;
        btn_clear = 0;
        btn_mode = 0;
        repeat(2) @(negedge clk);
        rst_n = 1;

        #100;
        btn_run = 1;
        #20_000_001; // 20ms
        btn_run = 0;


        #1000_000;
        
        btn_clear = 1;
        #100_000_000; // 1s
        btn_clear = 0;

        btn_mode = 1;
        #100_000_000; // 1s
        btn_mode = 0;

        btn_run = 1;
        #100_000_000; // 1s
        btn_run = 0;

        #100_000_000;

        #100;
        $stop;
    end

endmodule
