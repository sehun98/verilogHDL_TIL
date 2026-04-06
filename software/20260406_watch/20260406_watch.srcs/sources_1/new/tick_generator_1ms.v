`timescale 1ns / 1ps

// accumulator
module tick_generator_1ms(
    input  wire clk,
    input  wire rst_n,
    output reg  tick_1ms
);

parameter CLK_FREQ_HZ  = 100_000_000;
parameter TICK_RATE_HZ = 1000;

localparam ACC_STEP    = TICK_RATE_HZ;
localparam ACC_WIDTH   = $clog2(CLK_FREQ_HZ);
reg [ACC_WIDTH:0] phase_acc; // ACC_WIDTH-1 -> ACC_WIDTH

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        phase_acc <= 0;
        tick_1ms  <= 0;
    end else begin
        if (phase_acc + ACC_STEP >= CLK_FREQ_HZ) begin
            phase_acc <= phase_acc + ACC_STEP - CLK_FREQ_HZ;
            tick_1ms  <= 1;
        end else begin
            phase_acc <= phase_acc + ACC_STEP;
            tick_1ms  <= 0;
        end
    end
end

endmodule