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

    wire dht11;
    wire trig;
    reg echo;

    localparam CLK_PERIOD = 10;  // 100MHz
    localparam BAUD_RATE = 115200;
    localparam BIT_TIME = 1_000_000_000 / BAUD_RATE;  // ns 단위 약 8680ns
    localparam ECHO_TIME = 10000*58;

    wire debug_trig;

    top_system u1_top_system (
        .clk(clk),
        .rst_n(rst_n),

        .digit(digit),
        .seg(seg),
        .led(led),
        
        .btnR(btnR),
        .btnL(btnL),
        .btnU(btnU),
        .btnD(btnD),

        .setmode_sw(setmode_sw),
        .stopwatch_watch_sw(stopwatch_watch_sw),
        .hourmin_secmsec_sw(hourmin_secmsec_sw),
        
        .dht11(dht11),
        .trig(trig),
        .echo(echo),

        .rx(rx),
        .tx(tx)
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
    task send_ultrasonic_command;
        begin
            uart_send_byte("U");
            uart_send_byte("L");
            uart_send_byte("T");
            uart_send_byte("R");
            uart_send_byte("A");
            uart_send_byte("S");
            uart_send_byte("O");
            uart_send_byte("N");
            uart_send_byte("I");
            uart_send_byte("C");
            // uart_send_byte("0");
            // uart_send_byte(":");
            // uart_send_byte("0");
            // uart_send_byte("0");
            // uart_send_byte(":");
            // uart_send_byte("0");
            // uart_send_byte("0");
            uart_send_byte(8'h0A);  // \n
        end
    endtask
    task send_watch_command;
        begin
            uart_send_byte("W");
            uart_send_byte("A");
            uart_send_byte("T");
            uart_send_byte("C");
            uart_send_byte("H");
            uart_send_byte(" ");
            uart_send_byte("T");
            uart_send_byte("I");
            uart_send_byte("M");
            uart_send_byte("E");
            uart_send_byte(8'h0A);  // \n
        end
    endtask

    task send_dht11_command;
        begin
            uart_send_byte("D");
            uart_send_byte("H");
            uart_send_byte("T");
            uart_send_byte("1");
            uart_send_byte("1");
            uart_send_byte(8'h0A);  // \n
        end
    endtask

    assign debug_trig = u1_top_system.u1_top_stopwatch_watch.u13_ultrasonic.u1_ultrasonic_controller.trig;

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
        echo = 1'b0;

        rx = 1'b1;

        // reset
        #(CLK_PERIOD * 10);
        rst_n = 1;

        #(BIT_TIME * 5);

        $display("[%0t] Send command: LED ON", $time);
        send_ultrasonic_command();

        //repeat (16) uart_send_byte(8'h0A);
        @(negedge debug_trig);

        echo = 1;
        // 명령 파싱 및 실행 대기
        #(ECHO_TIME);
        echo = 0;


        if (led != 4'b0000) begin
            $display("[PASS] LED ON command executed. led = %b", led);
        end else begin
            $display("[FAIL] LED ON command failed. led = %b", led);
        end

        #(1000000);
        send_dht11_command();
        #(10000000);
        #(1000);
        $finish;
    end

endmodule
