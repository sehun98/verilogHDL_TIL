`timescale 1ns / 1ps

module tb_debounce;
    reg  clk;
    reg  rst_n;
    reg  din;
    wire dout;

    debounce #(
        .CLK_FREQ_HZ(100_000_000),
        .DEBOUNCE_MS(20)
    ) u1_debounce (
        .clk   (clk),
        .rst_n (rst_n),
        .din   (din),
        .dout  (dout)
    );

    // 100MHz clock -> 10ns period
    always #5 clk = ~clk;

    initial begin
        clk   = 0;
        rst_n = 0;
        din   = 0;

        // reset hold
        repeat(5) @(posedge clk);
        rst_n = 1;

        #(20_000_000);

        // -----------------------------
        // case 1: 짧은 bounce -> dout 바뀌면 안 됨
        // -----------------------------
        #100;
        din = 1; #1000;   // 1us
        din = 0; #1000;
        din = 1; #1000;
        din = 0; #1000;
        din = 1; #1000;
        din = 0; #1000;

        // 충분히 짧은 glitch라면 debounce 출력은 그대로 0 유지해야 함
        #10000;

        // -----------------------------
        // case 2: bounce 후 1로 안정
        // -----------------------------
        din = 1; #50000;
        din = 0; #30000;
        din = 1; #20000;
        din = 0; #10000;
        din = 1;

        // 20ms 이상 유지
        #(20_000_000);

        // 여기쯤에서 dout = 1 기대
        #1000;

        // -----------------------------
        // case 3: bounce 후 0으로 안정
        // -----------------------------
        din = 0; #40000;
        din = 1; #20000;
        din = 0; #30000;
        din = 1; #10000;
        din = 0;

        // 다시 20ms 이상 유지
        #(40_000_000);

        // 여기쯤에서 dout = 0 기대
        #1000;

        $finish;
    end

endmodule