`timescale 1ns / 1ps
/*
module tb_uart_rx;
    reg clk;
    reg rst_n;
    wire tx_start;
    wire [7:0] tx_data;
    wire [7:0] rx_data;
    wire rx_done;
    wire tx_busy;
    wire tx;
    wire rx;

    wire w_b_rx_tick;
    parameter DELAY = 100_000_00;

    top_uart_tx_shift u1_top_uart_tx_shift (
        .clk(clk),
        .rst_n(rst_n),

        .tx_start(rx_done),
        .tx_data(rx_data),
        .tx_busy(),

        .rx_data(tx_data),
        .rx_done(tx_start),

        .tx(tx),
        .rx(rx)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst_n = 0;
        b_tick = 0;
        rx = 1;
        repeat (5) @(negedge clk);

        rst_n = 1;
        #(DELAY);

        // 1010_1010
        @(negedge w_b_rx_tick);
        rx = 0;  // START bit
        repeat (16) @(negedge w_b_rx_tick);
        rx = 1;  // Bit0
        repeat (16) @(negedge w_b_rx_tick);
        rx = 0;  // Bit1
        repeat (16) @(negedge w_b_rx_tick);
        rx = 1;  // Bit2
        repeat (16) @(negedge w_b_rx_tick);
        rx = 0;  // Bit3
        repeat (16) @(negedge w_b_rx_tick);
        rx = 1;  // Bit4
        repeat (16) @(negedge w_b_rx_tick);
        rx = 0;  // Bit5
        repeat (16) @(negedge w_b_rx_tick);
        rx = 1;  // Bit6
        repeat (16) @(negedge w_b_rx_tick);
        rx = 0;  // Bit7
        repeat (16) @(negedge w_b_rx_tick);
        rx = 1;  // STOP bit
        repeat (16) @(negedge w_b_rx_tick);

        $finish;

    end

endmodule
*/