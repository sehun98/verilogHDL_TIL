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

    task send_flag;
    begin
        @(negedge clk);
        #2;
        tx_send = 1;
        @(posedge clk);
        @(negedge clk);   
        tx_send = 0;     
    end
    endtask

    task set_bit(
        input [7:0] t_data
    );
        begin
            tx_data = t_data;
        end
    endtask

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst_n = 0;
        tx_send = 0;
        tx_data = 0;
        repeat(5) @(negedge clk);
        rst_n = 1;

        #(DELAY);
        set_bit(8'h30);
        send_flag();

        #(DELAY);
        set_bit(8'h30);
        send_flag();
        repeat(16*5) @(posedge w_baud_tick_acc);
        set_bit(8'hff);
        send_flag();


        #(DELAY);
        $finish;        
    end

endmodule
