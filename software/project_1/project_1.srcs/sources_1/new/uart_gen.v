`timescale 1ns / 1ps

module uart_gen #(
    parameter CLOCK_FREQ_HZ = 100_000_000,
    parameter BAUD_TICK = 115200
) (
    input wire clk,
    input wire rst_n,
    output reg tx_baudrate,
    output reg rx_baudrate
);
    localparam COUNT_WIDTH = $clog2(CLOCK_FREQ_HZ);
    localparam TX_BAUD_TICK = BAUD_TICK;
    localparam RX_BAUD_TICK = (BAUD_TICK * 16);

    reg [COUNT_WIDTH:0] count_tx;
    reg [COUNT_WIDTH:0] count_rx;

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            count_tx <= 1'b0;
            tx_baudrate <= 1'b0;
        end else begin
            if(count_tx + TX_BAUD_TICK >= CLOCK_FREQ_HZ) begin
                count_tx <= count_tx + TX_BAUD_TICK - CLOCK_FREQ_HZ; 
                tx_baudrate <= 1'b1;
            end else begin
                count_tx <= count_tx + TX_BAUD_TICK;
                tx_baudrate <= 1'b0;
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            count_rx <= 1'b0;
            rx_baudrate <= 1'b0;
        end else begin
            if(count_rx + RX_BAUD_TICK >= CLOCK_FREQ_HZ) begin
                count_rx <= count_rx + RX_BAUD_TICK - CLOCK_FREQ_HZ; 
                rx_baudrate <= 1'b0;
            end else begin
                count_rx <= count_rx + RX_BAUD_TICK;
                rx_baudrate <= 1'b0;
            end
        end
    end

endmodule
