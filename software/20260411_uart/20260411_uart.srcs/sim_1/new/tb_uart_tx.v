`timescale 1ns / 1ps

module tb_uart_tx;
    reg        clk;
    reg        rst_n;
    wire       tx_baud_tick;
    wire       rx_baud_tick;

    reg        send;
    wire       busy;
    wire       done;

    reg  [7:0] data;
    wire       tx;

    uart_tx u1_uart_tx (
        .clk(clk),
        .rst_n(rst_n),
        .tx_baud_tick(tx_baud_tick),
        .send(send),
        .busy(busy),
        .done(done),
        .data(data),
        .tx(tx)
    );

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
        clk  = 1'b0;
        rst_n = 1'b0;
        send = 1'b0;
        data = 8'd0;

        #50;
        rst_n = 1'b1;

        // Scenario 1 : transmit 8'd1
        data = 8'd1;

        @(posedge clk);
        #1 send = 1'b1;
        @(posedge clk);
        #1 send = 1'b0;

        @(posedge done);

        // Scenario 2 : transmit 8'd255
        data = 8'd255;
        @(posedge clk);
        #1 send = 1'b1;
        @(posedge clk);
        #1 send = 1'b0;

        @(posedge done);

        // Scenario 3 : transmit 8'd123
        data = 8'd123;
        @(posedge clk);
        #1 send = 1'b1;
        @(posedge clk);
        #1 send = 1'b0;

        @(posedge done);
        #100;
        $finish;
    end

    always #5 clk = ~clk;

endmodule