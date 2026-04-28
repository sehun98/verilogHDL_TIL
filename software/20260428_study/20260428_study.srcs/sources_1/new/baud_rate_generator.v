`timescale 1ns / 1ps

module baud_rate_generator #(
    parameter CLOCK_FREQ_HZ = 100_000_000,
    parameter BAUD_RATE = 115200
) (
    input  wire clk,
    input  wire rst_n,
    output reg  baud_tick
);
    localparam CNT = CLOCK_FREQ_HZ / BAUD_RATE;
    localparam CNT_WIDTH = $clog2(CNT);

    reg [CNT_WIDTH-1:0] cnt;

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            cnt <= {CNT_WIDTH{1'b0}};
            baud_tick <= 1'b0;
        end else begin
            if(cnt==CNT-1) begin
                cnt <= {CNT_WIDTH{1'b0}};
                baud_tick <= 1'b1;
            end else begin
                cnt <= cnt + 1'b1;
                baud_tick <= 1'b0;
            end
        end
    end


endmodule
