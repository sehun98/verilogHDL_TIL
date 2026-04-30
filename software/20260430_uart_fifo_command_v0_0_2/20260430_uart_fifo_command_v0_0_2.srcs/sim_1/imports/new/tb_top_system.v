`timescale 1ns / 1ps

module tb_top_system;

    reg clk;
    reg rst_n;

    reg rx;
    wire tx;

    wire [3:0] digit;
    wire [7:0] seg;
    wire [1:0] led;

    reg btnR;
    reg btnL;
    reg btnU;
    reg btnD;

    reg setmode_sw;
    reg stopwatch_watch_sw;
    reg hourmin_secmsec_sw;

    localparam CLK_PERIOD = 10;  // 100MHz
    localparam BAUD_RATE = 115200;
    localparam BIT_TIME = 1_000_000_000 / BAUD_RATE;  // ns 단위 약 8680ns

    top_system u1_top_system (
        .clk(clk),
        .rst_n(rst_n),
        .digit(digit),
        .seg(seg),
        .led(led),
        .rx(rx),
        .tx(tx),
        
        .btnR(btnR),
        .btnL(btnL),
        .btnU(btnU),
        .btnD(btnD),
        .setmode_sw(setmode_sw),
        .stopwatch_watch_sw(stopwatch_watch_sw),
        .hourmin_secmsec_sw(hourmin_secmsec_sw)
    );


    // 100MHz clock
    always #(CLK_PERIOD / 2) clk = ~clk;

    // UART 1 byte 전송 task
    task uart_send_byte;
        input [7:0] data;
        integer i;
        begin
            // idle 상태
            rx = 1'b1;
            #(BIT_TIME);

            // start bit
            rx = 1'b0;
            #(BIT_TIME);

            // data bit, LSB first
            for (i = 0; i < 8; i = i + 1) begin
                rx = data[i];
                #(BIT_TIME);
            end

            // stop bit
            rx = 1'b1;
            #(BIT_TIME);
        end
    endtask

    // 문자열 "LED ON\n" 전송
    task send_led_on_command;
        begin
            uart_send_byte("W");
            uart_send_byte("A");
            uart_send_byte("T");
            uart_send_byte("C");
            //uart_send_byte("H");
            uart_send_byte(" ");
            uart_send_byte("1");
            uart_send_byte("3");
            uart_send_byte(":");
            uart_send_byte("0");
            uart_send_byte("0");
            uart_send_byte(":");
            uart_send_byte("0");
            uart_send_byte("0");
            uart_send_byte(":");
            uart_send_byte("0");
            uart_send_byte("0");
            uart_send_byte(8'h0A);  // \n
        end
    endtask

    initial begin
        // 초기값
        clk = 0;
        rst_n = 0;
        btnR = 0;
        btnL = 0;
        btnU = 0;
        btnD = 0;
        setmode_sw = 0;
        stopwatch_watch_sw = 0;
        hourmin_secmsec_sw = 0;

        rx = 1'b1;

        // reset
        #(CLK_PERIOD * 10);
        rst_n = 1;

        #(BIT_TIME * 5);

        $display("[%0t] Send command: LED ON", $time);
        send_led_on_command();

        repeat (16) uart_send_byte(8'h0A);

        // 명령 파싱 및 실행 대기
        #(BIT_TIME * 20);

        if (led != 4'b0000) begin
            $display("[PASS] LED ON command executed. led = %b", led);
        end else begin
            $display("[FAIL] LED ON command failed. led = %b", led);
        end

        #(BIT_TIME * 5);
        $finish;
    end

endmodule
