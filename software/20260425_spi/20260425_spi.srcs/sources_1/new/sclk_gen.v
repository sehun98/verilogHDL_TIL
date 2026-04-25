`timescale 1ns / 1ps

// 1.5625MHz
module sclk_gen #(
    parameter CLOCK_FREQ_HZ = 100_000_000,
    parameter DIV_HALF = 32
) (
    input  wire clk,
    input  wire rst_n,
    output reg sclk_square
);
    localparam CNT_WIDTH = $clog2(DIV_HALF);

    reg [CNT_WIDTH-1:0] cnt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt <= 0;
            sclk_square <= 1;
        end else begin
            if (cnt == DIV_HALF - 1) begin
                sclk_square <= ~sclk_square;
                cnt <= 0;
            end else begin
                cnt <= cnt + 1;
            end
        end
    end

endmodule
