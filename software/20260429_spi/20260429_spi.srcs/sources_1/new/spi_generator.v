`timescale 1ns / 1ps

module spi_generator #(
    parameter CLOCK_FREQ_HZ = 100_000_000,
    parameter SCK_FREQ_HZ = 100_000
) (
    input  wire clk,
    input  wire rst_n,
    output reg sck_square,
    output wire sck_rising_tick,
    output wire sck_falling_tick
);
    localparam CNT = CLOCK_FREQ_HZ / (2 * SCK_FREQ_HZ);
    localparam CNT_WIDTH = $clog2(CNT);

    reg [CNT_WIDTH-1:0] cnt;
    reg sck_square_prev;

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            cnt <= 0;
            sck_square <= 0;
        end else begin
            if(cnt == CNT-1) begin
                cnt <= 0;
                sck_square <= ~sck_square;
            end else begin
                cnt <= cnt + 1;
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            sck_square_prev <= 0;
        end else begin
            sck_square_prev <= sck_square;
        end
    end

    assign sck_rising_tick = sck_square & ~sck_square_prev;
    assign sck_falling_tick = ~sck_square & sck_square_prev;

endmodule
