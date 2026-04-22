`timescale 1ns / 1ps

module baud_tick_gen # (
    parameter CLOCK_FREQ_HZ = 100_000_000,
    parameter BAUD_RATE = 9600
) (
    input  wire clk,
    input  wire rst_n,
    output reg  b_tx_tick,
    output reg  b_rx_tick
);
    localparam COUNT_WIDTH = $clog2(CLOCK_FREQ_HZ);
    localparam TX_BAUD_RATE = BAUD_RATE;
    localparam RX_BAUD_RATE = BAUD_RATE * 16;

    reg [COUNT_WIDTH:0] tx_cnt;
    reg [COUNT_WIDTH:0] rx_cnt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_cnt <= 0;
            b_tx_tick <= 0;
        end else begin
            if (tx_cnt + TX_BAUD_RATE >= CLOCK_FREQ_HZ) begin
                tx_cnt <= tx_cnt + TX_BAUD_RATE - CLOCK_FREQ_HZ;
                b_tx_tick <= 1;
            end else begin
                tx_cnt <= tx_cnt + TX_BAUD_RATE;
                b_tx_tick <= 0;
            end
        end
    end
        always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_cnt <= 0;
            b_rx_tick <= 0;
        end else begin
            if (rx_cnt + RX_BAUD_RATE >= CLOCK_FREQ_HZ) begin
                rx_cnt <= rx_cnt + RX_BAUD_RATE - CLOCK_FREQ_HZ;
                b_rx_tick <= 1;
            end else begin
                rx_cnt <= rx_cnt + RX_BAUD_RATE;
                b_rx_tick <= 0;
            end
        end
    end

endmodule

module baud_tick_gen_2 # (
    parameter CLOCK_FREQ_HZ = 100_000_000,
    parameter BAUD_RATE = 9600
) (
    input  wire clk,
    input  wire rst_n,
    output reg  b_rx_tick
);
    localparam COUNT_WIDTH = $clog2(CLOCK_FREQ_HZ);
    localparam RX_BAUD_RATE = BAUD_RATE * 16;

    reg [COUNT_WIDTH:0] rx_cnt;

        always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_cnt <= 0;
            b_rx_tick <= 0;
        end else begin
            if (rx_cnt + RX_BAUD_RATE >= CLOCK_FREQ_HZ) begin
                rx_cnt <= rx_cnt + RX_BAUD_RATE - CLOCK_FREQ_HZ;
                b_rx_tick <= 1;
            end else begin
                rx_cnt <= rx_cnt + RX_BAUD_RATE;
                b_rx_tick <= 0;
            end
        end
    end

endmodule