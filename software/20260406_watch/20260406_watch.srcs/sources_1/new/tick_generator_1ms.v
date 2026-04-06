`timescale 1ns / 1ps

module tick_generator_1ms (
    input  wire clk,
    input  wire rst_n,
    output reg  tick_1ms
);

    // ===== Parameters =====
    parameter CLK_FREQ_HZ = 100_000_000;  // 입력 클럭 (Hz)
    parameter TICK_RATE_HZ = 1000;  // 1ms = 1kHz

    localparam CLK_DIV = CLK_FREQ_HZ / TICK_RATE_HZ;
    localparam COUNTER_WIDTH = $clog2(CLK_DIV);

    // ===== Registers =====
    reg [COUNTER_WIDTH-1:0] cycle_cnt;

    // ===== Logic =====
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cycle_cnt <= 0;
            tick_1ms  <= 0;
        end else begin
            if (cycle_cnt == CLK_DIV - 1) begin
                cycle_cnt <= 0;
                tick_1ms  <= 1;
            end else begin
                cycle_cnt <= cycle_cnt + 1;
                tick_1ms  <= 0;
            end
        end
    end

endmodule
