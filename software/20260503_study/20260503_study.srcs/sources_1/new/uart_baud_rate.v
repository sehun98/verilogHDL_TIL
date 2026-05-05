`timescale 1ns / 1ps

module uart_baud_rate #(
    parameter CLOCK_FREQ_HZ = 100_000_000,
    parameter BAUD_RATE = 115200
) (
    input  wire clk,
    input  wire rst_n,
    output reg baud_tick
);

    localparam BAUD_RATE_16 = BAUD_RATE * 16;

    localparam CNT = CLOCK_FREQ_HZ / BAUD_RATE_16;
    localparam CNT_WIDTH = $clog2(CNT);

    reg [CNT_WIDTH-1:0] cnt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            baud_tick <= 1'b0;
            cnt <= {CNT_WIDTH{1'b0}};
        end else begin
            if(cnt==CNT-1) begin
                baud_tick <= 1'b1;
                cnt <= {CNT_WIDTH{1'b0}};
            end else begin
                baud_tick <= 1'b0;
                cnt <= cnt + 1'b1;
            end
        end
    end
endmodule
