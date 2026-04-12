`timescale 1ns / 1ps

module tb_uart_rx;
    reg clk;
    reg rst_n;
    wire rx_baud_tick;
    wire busy;
    wire done;
    wire [7:0] data;
    reg rx;

    wire tx_baud_tick;

    uart_rx u1_uart_rx (
        .clk(clk),
        .rst_n(rst_n),
        .rx_baud_tick(rx_baud_tick),
        .busy(busy),
        .done(done),
        .data(data),
        .rx(rx)
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
        clk = 1'b0;
        rst_n = 1'b0;
        rx = 1'b1;
        repeat (5) @(posedge clk);
        rst_n = 1'b1;
    end

    always #5 clk = ~clk;

    task send_bit(input reg b);
        begin
            rx = b;
            repeat (16) @(posedge rx_baud_tick);
        end
    endtask

    initial begin
        @(posedge rst_n);
        #1000_000;

        // send 85 = 0101_0101 (LSB first)
        send_bit(1'b0);  // start
        send_bit(1'b1);  // bit0
        send_bit(1'b0);  // bit1
        send_bit(1'b1);  // bit2
        send_bit(1'b0);  // bit3
        send_bit(1'b1);  // bit4
        send_bit(1'b0);  // bit5
        send_bit(1'b1);  // bit6
        send_bit(1'b0);  // bit7
        send_bit(1'b1);  // stop

        #1000_000;

        // send 165 = 1010_0101 (LSB first)
        send_bit(1'b0);  // start
        send_bit(1'b1);  // bit0
        send_bit(1'b0);  // bit1
        send_bit(1'b1);  // bit2
        send_bit(1'b0);  // bit3
        send_bit(1'b0);  // bit4
        send_bit(1'b1);  // bit5
        send_bit(1'b0);  // bit6
        send_bit(1'b1);  // bit7
        send_bit(1'b1);  // stop

        #1000_000;
        // stop bit 0 error
        send_bit(1'b0);  // start
        send_bit(1'b1);  // bit0
        send_bit(1'b1);  // bit1
        send_bit(1'b1);  // bit2
        send_bit(1'b1);  // bit3
        send_bit(1'b1);  // bit4
        send_bit(1'b1);  // bit5
        send_bit(1'b1);  // bit6
        send_bit(1'b1);  // bit7
        send_bit(1'b0);  // stop
        
        #1000_000;
        send_bit(1'b1); 
        #1000_000;
        $finish;
    end

    always @(posedge done) begin
        $display("[%0t] RX done, data = 0x%02h", $time, data);
    end

endmodule
