`timescale 1ns / 1ps

// accumulator method tick generator
module tick_generator_1ms #(
    parameter CLOCK_FREQ_HZ = 100_000_000,
    parameter TICK_HZ = 1000,

    localparam COUNT_WIDTH = $clog2(CLOCK_FREQ_HZ)
) (
    input  wire clk,
    input  wire rst_n,
    output reg  tick_1ms
);
    reg [COUNT_WIDTH:0] count;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= {COUNT_WIDTH{1'b0}};
            tick_1ms <= 1'b0;
        end else begin
            if (count + TICK_HZ >= CLOCK_FREQ_HZ) begin
                count <= count + TICK_HZ - CLOCK_FREQ_HZ;
                tick_1ms <= 1'b1;
            end else begin
                count <= count + TICK_HZ;
                tick_1ms <= 1'b0;
            end
        end
    end

endmodule
