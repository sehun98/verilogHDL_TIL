`timescale 1ns / 1ps

module tb_baud_rate_acc_cnt_comparate;

    reg  clk;
    reg  rst_n;
    wire baud_tick_cnt;
    wire baud_tick_acc;

    reg [31:0] tick_count_acc;
    reg [31:0] tick_count_cnt;

    uart_baud_rate_acc #(
        .CLOCK_FREQ_HZ(100_000_000),
        .BAUD_RATE(115200)
    ) u1_uart_baud_rate_acc (
        .clk(clk),
        .rst_n(rst_n),
        .baud_tick(baud_tick_acc)
    );

    uart_baud_rate_cnt #(
        .CLOCK_FREQ_HZ(100_000_000),
        .BAUD_RATE(115200)
    ) u2_uart_baud_rate_cnt (
        .clk(clk),
        .rst_n(rst_n),
        .baud_tick(baud_tick_cnt)
    );

    always #5 clk = ~clk;   // 100MHz

    initial begin
        clk            = 0;
        rst_n          = 0;
        tick_count_acc = 0;
        tick_count_cnt = 0;

        repeat (5) @(negedge clk);
        rst_n = 1;

        // 1ms 측정 : 100MHz => 100,000 clocks
        #(100_000);
        $display("[%0t] tick_count_acc = %0d, tick_count_cnt = %0d",
                 $time, tick_count_acc, tick_count_cnt);
        rst_n = 0;
        #(100_000);
        #100;
        $finish;
    end

    always @(posedge clk) begin
        if (rst_n && baud_tick_acc)
            tick_count_acc <= tick_count_acc + 1;
    end

    always @(posedge clk) begin
        if (rst_n && baud_tick_cnt)
            tick_count_cnt <= tick_count_cnt + 1;
    end

endmodule