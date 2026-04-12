`timescale 1ns / 1ps

module top_uart (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       uart_rx,
    output wire       uart_tx
);

    wire        tx_baud_tick;
    wire        rx_baud_tick;

    wire        tx_busy;
    wire        tx_done;
    reg         tx_send;
    reg  [7:0]  tx_data;

    wire        rx_busy;
    wire        rx_done;
    wire [7:0]  rx_data;

    reg         pending_valid;
    reg  [7:0]  pending_data;

    // Baudrate generator
    uart_baudrate_gen #(
        .CLOCK_FREQ_HZ(100_000_000),
        .BAUD_RATE(115200)
    ) u_uart_baudrate_gen (
        .clk(clk),
        .rst_n(rst_n),
        .tx_baud_tick(tx_baud_tick),
        .rx_baud_tick(rx_baud_tick)
    );

    // UART TX
    uart_tx u_uart_tx (
        .clk(clk),
        .rst_n(rst_n),
        .tx_baud_tick(tx_baud_tick),
        .send(tx_send),
        .busy(tx_busy),
        .done(tx_done),
        .data(tx_data),
        .tx(uart_tx)
    );

    // UART RX
    uart_rx u_uart_rx (
        .clk(clk),
        .rst_n(rst_n),
        .rx_baud_tick(rx_baud_tick),
        .busy(rx_busy),
        .done(rx_done),
        .data(rx_data),
        .rx(uart_rx)
    );

    // Echo controller
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_send       <= 1'b0;
            tx_data       <= 8'd0;
            pending_valid <= 1'b0;
            pending_data  <= 8'd0;
        end else begin
            // default: send is 1-cycle pulse
            tx_send <= 1'b0;

            // received byte latch
            if (rx_done) begin
                pending_data  <= rx_data;
                pending_valid <= 1'b1;
            end

            // transmit when TX is idle
            if (pending_valid && !tx_busy) begin
                tx_data       <= pending_data+1;
                tx_send       <= 1'b1;
                pending_valid <= 1'b0;
            end
        end
    end

endmodule