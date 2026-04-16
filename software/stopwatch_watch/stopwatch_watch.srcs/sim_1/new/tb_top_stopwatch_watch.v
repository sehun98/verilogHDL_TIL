`timescale 1ns / 1ps

module tb_top_stopwatch_watch;
    reg        clk;
    reg        rst_n;

    reg        btnR;  // stopwatch : run    / watch : 자릿수 오르쪽
    reg        btnL;  // stopwatch : clear  / watch : 자릿수 왼쪽
    reg        btnU;  // stopwatch : X      / watch : 값 Up
    reg        btnD;  // stopwatch : mode   / watch : 값 Down

    reg  [2:0] sw;  // sw[0] : High : msec/sec, LOW : min/hour

    wire [7:0] seg;
    wire [3:0] digit;
    wire [1:0] led;

    top_stopwatch_watch u1_top_stopwatch_watch (
        .clk(clk),
        .rst_n(rst_n),
        .btnR(btnR),
        .btnL(btnL),
        .btnU(btnU),
        .btnD(btnD),
        .sw(sw),
        .seg(seg),
        .digit(digit),
        .led(led)
    );

    localparam DELAY_SET = 100_000_000;

    always #5 clk = ~clk;

    initial begin
        {clk, rst_n} = 2'b00;
        {btnR, btnL, btnU, btnD} = 4'b0000;
        sw = 3'b000;

        repeat (5) @(posedge clk);
        rst_n = 1;

        btnR = 1;
        repeat(5) #(DELAY_SET);

        btnR = 0;
        repeat(5) #(DELAY_SET);
        $finish;
    end

endmodule
