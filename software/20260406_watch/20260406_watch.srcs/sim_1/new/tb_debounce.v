`timescale 1ns / 1ps

module tb_debounce;
    reg  clk;
    reg  rst_n;
    reg  din;
    wire dout;

    initial begin
        {clk, rst_n, din} = 3'b000;
        #10 rst_n = 1'b1;
    end

    always #5 clk = ~clk;

    initial begin
        #20_000_000  // 20ms
        din = 1;
        #20_000;  // 20us
        din = 0;
        #30_000;  // 30us
        din = 1;
        #15_000;  // 15us
        din = 0;
        #25_000;  // 25us
        din = 1;
        #15_000;  // 15us
        din = 0;
        #25_000;  // 25us
        din = 1;
        #20_000_000;  // 20ms
        din = 0;
        #20_000_000;  // 20ms
    end

    debounce #(
        .CLK_FREQ_HZ(100_000_000),
        .DEBOUNCE_MS(20)
    ) u1_debounce (
        .clk  (clk),
        .rst_n(rst_n),
        .din  (din),
        .dout (dout)
    );
endmodule
