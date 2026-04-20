`timescale 1ns / 1ps

module uart_baudrate_gen #(
    parameter CLOCK_FREQ_HZ = 100_000_000,
    parameter BAUD_RATE = 115200
) (
    input  wire clk,
    input  wire rst_n,
    output reg  tx_baud_tick,
    output reg  rx_baud_tick
);
    localparam TX_BAUD_RATE = BAUD_RATE;
    localparam RX_BAUD_RATE = BAUD_RATE * 16;

    localparam COUNT_WIDTH = $clog2(CLOCK_FREQ_HZ);

    reg [COUNT_WIDTH:0] count_tx;
    reg [COUNT_WIDTH:0] count_rx;

    // tx_baudrate acculmulate
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count_tx <= 0;
            tx_baud_tick <= 0;
        end else begin
            if (count_tx + TX_BAUD_RATE >= CLOCK_FREQ_HZ) begin
                count_tx <= count_tx + TX_BAUD_RATE - CLOCK_FREQ_HZ;
                tx_baud_tick <= 1;
            end else begin
                count_tx <= count_tx + TX_BAUD_RATE;
                tx_baud_tick <= 0;
            end
        end
    end

    // rx_baudrate acculmulate
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count_rx <= 0;
            rx_baud_tick <= 0;
        end else begin
            if (count_rx + RX_BAUD_RATE >= CLOCK_FREQ_HZ) begin
                count_rx <= count_rx + RX_BAUD_RATE - CLOCK_FREQ_HZ;
                rx_baud_tick <= 1;
            end else begin
                count_rx <= count_rx + RX_BAUD_RATE;
                rx_baud_tick <= 0;
            end
        end
    end

endmodule
