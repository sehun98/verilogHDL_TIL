`timescale 1ns / 1ps

module tb_top_uart;
    reg       clk;
    reg       rst_n;
    reg       btn_send;
    reg [7:0] sw;
    wire        uart_tx;

    top_uart u1_top_uart (
        .clk(clk),
        .rst_n(rst_n),
        .btn_send(btn_send),
        .sw(sw),
        .uart_tx(uart_tx)
    );

    always #5 clk = ~clk;

    initial begin
        {clk, rst_n} = 2'b00;
        btn_send = 1'b0;
        sw = 8'd0;
        repeat (5) @(posedge clk);
        rst_n = 1'b1;

        #100;
        sw = 8'd123;
        btn_send = 0;

        @(posedge clk);
        #1 btn_send = 1'b1;
        #1000_000_000;
        #1 btn_send = 1'b0;

    end

endmodule
