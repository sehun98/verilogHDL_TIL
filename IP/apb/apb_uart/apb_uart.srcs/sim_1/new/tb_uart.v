`timescale 1ns / 1ps

module tb_uart;
    reg  clk;
    reg  rst_n;
    reg  rx;
    wire tx;
    wire led;

    localparam CLOCK_PERIOD = 10;      // 100MHz
    localparam BAUD_PERIOD  = 8680;    // 115200bps 기준 약 8.68us

    integer i;

    uart_loopback u1_uart_loopback (
        .clk(clk),
        .rst_n(rst_n),
        .rx(rx),
        .tx(tx),
        .led(led)
    );

    always #(CLOCK_PERIOD/2) clk = ~clk;

    task send_uart_byte;
        input [7:0] data;
        begin
            // Start bit
            rx = 1'b0;
            #(BAUD_PERIOD);

            // Data bit, LSB first
            for (i = 0; i < 8; i = i + 1) begin
                rx = data[i];
                #(BAUD_PERIOD);
            end

            // Stop bit
            rx = 1'b1;
            #(BAUD_PERIOD);
        end
    endtask

    initial begin
        clk = 0;
        rst_n = 0;
        rx = 1'b1;   // UART idle 상태는 high

        #100;
        rst_n = 1;

        #100000;

        // 단일 문자 loopback 확인
        send_uart_byte(8'h30);   // '0'

        #200000;

        // 연속 문자 loopback 확인
        send_uart_byte(8'h30);   // '0'
        send_uart_byte(8'h30);   // '0'
        send_uart_byte(8'h30);   // '0'
        send_uart_byte(8'h30);   // '0'
        send_uart_byte(8'h30);   // '0'
        send_uart_byte(8'h30);   // '0'
        send_uart_byte(8'h30);   // '0'
        send_uart_byte(8'h30);   // '0'
        send_uart_byte(8'h30);   // '0'
        send_uart_byte(8'h30);   // '0'
        send_uart_byte(8'h30);   // '0'
        send_uart_byte(8'h30);   // '0'
        
        #1000000;
        $finish;
    end

endmodule