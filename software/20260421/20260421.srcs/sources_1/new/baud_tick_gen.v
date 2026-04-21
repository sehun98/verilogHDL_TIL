`timescale 1ns / 1ps

module baud_tick_gen # (
    parameter CLOCK_FREQ_HZ = 100_000_000,
    parameter BAUD_RATE = 9600
) (
    input  wire clk,
    input  wire rst_n,
    output reg  b_tick
);
    localparam COUNT_WIDTH = $clog2(CLOCK_FREQ_HZ);
    reg [COUNT_WIDTH:0] cnt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt <= 0;
            b_tick <= 0;
        end else begin
            if (cnt + BAUD_RATE >= CLOCK_FREQ_HZ) begin
                cnt <= cnt + BAUD_RATE - CLOCK_FREQ_HZ;
                b_tick <= 1;
            end else begin
                cnt <= cnt + BAUD_RATE;
                b_tick <= 0;
            end
        end
    end

endmodule