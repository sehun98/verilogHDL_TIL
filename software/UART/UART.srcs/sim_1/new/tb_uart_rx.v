`timescale 1ns / 1ps

// 시나리오 1 : 정상 동작 확인
// 시나리오 2 : 연속 정상 동작 확인
// 시나리오 3 : 데이터 전송 과정 중 데이터가 바뀔 때 ?
// 시나리오 4 : STOP bit 가 1이 아닐 때 frame error가 발생하는지
// 시나리오 5 : start bit 글리치 발생 했을 때
// 시나리오 6 : baud rate가 약간 달라질때 정상 동작 범위가 어디인지 확인

module tb_uart_rx;
    reg clk;
    reg rst_n;
    wire w_baud_tick_acc;
    reg rx;
    wire rx_done;
    wire [7:0] rx_data;
    wire rx_frame_error;

    uart_baud_rate_acc #(
        .CLOCK_FREQ_HZ(100_000_000),
        .BAUD_RATE(115200)
    ) u1_uart_baud_rate_acc (
        .clk(clk),
        .rst_n(rst_n),
        .baud_tick(w_baud_tick_acc)
    );

    uart_rx uart_rx (
        .clk(clk),
        .rst_n(rst_n),
        .rx_baud_tick(w_baud_tick_acc),
        .rx(rx),
        .rx_done(rx_done),
        .rx_data(rx_data),
        .rx_frame_error(rx_frame_error)
    );

    localparam DELAY = 100_000;

    integer i;

    task set_data;
        input [7:0] t_data;
        begin
            #3;
            rx = 1'b0;  // start bit
            repeat (16) @(negedge w_baud_tick_acc);

            for (i = 0; i < 8; i = i + 1) begin
                rx = t_data[i];
                repeat (16) @(negedge w_baud_tick_acc);
            end

            rx = 1'b1;  // stop bit
            repeat (16) @(negedge w_baud_tick_acc);
        end
    endtask

    task set_data_stop_bit_not_1;
        input [7:0] t_data;
        begin
            rx = 1'b0;  // start bit
            repeat (16) @(negedge w_baud_tick_acc);

            for (i = 0; i < 8; i = i + 1) begin
                rx = t_data[i];
                repeat (16) @(negedge w_baud_tick_acc);
            end

            rx = 1'b0;  // stop bit
            repeat (16) @(negedge w_baud_tick_acc);
            rx = 1'b1;
        end
    endtask

    task set_data_start_glitch;
        begin
            rx = 1'b0;  // start bit
            repeat (5) @(negedge w_baud_tick_acc);
            rx = 1'b1;
            repeat (15) @(negedge w_baud_tick_acc);
        end
    endtask

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst_n = 0;
        rx = 1;
        repeat (5) @(negedge clk);
        rst_n = 1;

        #(DELAY);
        set_data(8'h30);  // '0'

        #(DELAY);
        set_data(8'h30);  // 

        #(DELAY);
        rx = 1'b0;  // start bit
        repeat (16) @(negedge w_baud_tick_acc);

        rx = 0;
        repeat (16) @(negedge w_baud_tick_acc);
        rx = 0;
        repeat (16) @(negedge w_baud_tick_acc);
        rx = 0;
        repeat (16) @(negedge w_baud_tick_acc);
        rx = 0;
        set_data(8'h30);
        #(DELAY);

        set_data_stop_bit_not_1(8'h30);
        #(DELAY);

        set_data_start_glitch();
        #(DELAY);
        $finish;
    end

endmodule
