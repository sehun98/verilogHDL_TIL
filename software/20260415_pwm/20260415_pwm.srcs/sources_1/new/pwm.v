`timescale 1ns / 1ps

module pwm #(
    parameter CLOCK_FREQ_HZ = 100_000_000,
    parameter CNT_WIDTH = 19
) (
    input wire clk,
    input wire rst_n,
    input wire [CNT_WIDTH-1:0] period,  // 100_000_000 / 1000Hz = 100_000
    input wire [CNT_WIDTH-1:0] duty,  // 0~100% need change 100_000 / 2 = 50_000
    output reg pwm
);
    reg [CNT_WIDTH-1:0] cnt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt <= 0;
        end else if (cnt >= period - 1) begin
            cnt <= 0;
        end else begin
            cnt <= cnt + 1'b1;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pwm <= 1'b0;
        end else begin
            pwm <= (cnt < duty);  // (cnt < period >> 1); 50% fix
        end
    end

endmodule
