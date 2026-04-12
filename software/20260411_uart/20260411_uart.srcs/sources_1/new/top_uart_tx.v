`timescale 1ns / 1ps

module top_uart_tx (
    input  wire clk,
    input  wire rst_n,
    output wire uart_tx
);

    wire tx_baud_tick;
    wire rx_baud_tick;
    wire busy;
    wire done;

    reg [26:0] cnt;
    reg send;
    reg [7:0] data;

    uart_tx u1_uart_tx (
        .clk(clk),
        .rst_n(rst_n),
        .tx_baud_tick(tx_baud_tick),
        .send(send),
        .busy(busy),
        .done(done),
        .data(data),
        .tx(uart_tx)
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

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt  <= 27'd0;
            send <= 1'b0;
            data <= 8'h41; // 'A'
        end else begin
            send <= 1'b0;

            if (cnt == 27'd99_999_999) begin
                cnt <= 27'd0;
                if (!busy)
                    send <= 1'b1;
            end else begin
                cnt <= cnt + 27'd1;
            end
        end
    end

endmodule