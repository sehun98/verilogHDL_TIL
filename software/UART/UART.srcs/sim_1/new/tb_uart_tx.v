`timescale 1ns / 1ps

module tb_uart_tx;
    localparam CLOCK_FREQ_HZ = 100_000_000;
    localparam BAUD_RATE = 115200;
    localparam DELAY = 1_000_000;

    reg clk;
    reg rst_n;

    reg [7:0] tx_data;
    reg tx_send;
    wire tx_busy;
    wire tx_overrun_error;
    wire tx;

    wire w_baud_tick_acc;


    uart_baud_rate_acc #(
        .CLOCK_FREQ_HZ(CLOCK_FREQ_HZ),
        .BAUD_RATE(BAUD_RATE)
    ) u1_uart_baud_rate_acc (
        .clk(clk),
        .rst_n(rst_n),
        .baud_tick(w_baud_tick_acc)
    );

    uart_tx u2_uart_tx (
        .clk(clk),
        .rst_n(rst_n),
        .tx_baud_tick(w_baud_tick_acc),
        .tx_data(tx_data),
        .tx_send(tx_send),
        .tx_busy(tx_busy),
        .tx_overrun_error(tx_overrun_error),
        .tx(tx)
    );

    task send_byte(input [7:0] t_data);
        begin
            // TX가 사용 가능할 때까지 대기
            wait (tx_busy == 0);

            @(negedge clk);
            tx_data = t_data;
            tx_send = 1;

            @(negedge clk);
            tx_send = 0;

            // 전송 시작 확인
            wait (tx_busy == 1);

            // 전송 완료 대기
            wait (tx_busy == 0);
        end
    endtask

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst_n = 0;
        tx_send = 0;
        tx_data = 0;

        repeat (5) @(negedge clk);
        rst_n = 1;

        #(DELAY);

        send_byte(8'h30);
        send_byte(8'h30);
        send_byte(8'h30);
        send_byte(8'h30);
        send_byte(8'h30);
        send_byte(8'h30);
        send_byte(8'h30);
        send_byte(8'h30);
        send_byte(8'h30);
        send_byte(8'h30);
        send_byte(8'h30);

        #(DELAY);
        $finish;
    end

endmodule
