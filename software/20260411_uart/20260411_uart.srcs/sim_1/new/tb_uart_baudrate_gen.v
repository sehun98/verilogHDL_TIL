`timescale 1ns / 1ps

module tb_uart_baudrate_gen;
    reg  clk;
    reg  rst_n;
    wire tx_baud_tick;
    wire rx_baud_tick;

    uart_baudrate_gen #(
        .CLOCK_FREQ_HZ(100_000_000),
        .BAUD_RATE(115200)
    ) u1_uart_baudrate_gen (
        .clk(clk),
        .rst_n(rst_n),
        .tx_baud_tick(tx_baud_tick),
        .rx_baud_tick(rx_baud_tick)
    );

    initial begin
        {clk,rst_n} = 2'b00;
        #50
        rst_n = 1'b1;
    end

    always #5 clk = ~clk;

    initial begin
        repeat(16) @(posedge tx_baud_tick);
        $finish;
    end

endmodule
