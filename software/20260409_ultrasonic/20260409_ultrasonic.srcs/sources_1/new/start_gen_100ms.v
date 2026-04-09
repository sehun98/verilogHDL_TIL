`timescale 1ns / 1ps

module start_gen_100ms #(
    parameter CLOCK_FREQ = 100_000_000,
    localparam TICK_10HZ = CLOCK_FREQ / 10,
    localparam TICK_COUNT_WIDTH = $clog2(TICK_10HZ)
) (
    input  wire clk,
    input  wire rst_n,
    output reg  tick_10hz
);

    reg [TICK_COUNT_WIDTH-1:0] count;

    // 1ms FND 10Hz 10000진 counter
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= {TICK_COUNT_WIDTH{1'b0}};
            tick_10hz <= 1'b0;
        end else begin
            count <= count + 1'b1;
            tick_10hz <= 1'b0;
            if (count == (TICK_10HZ - 1)) begin
                count <= {TICK_COUNT_WIDTH{1'b0}};
                tick_10hz <= 1'b1;
            end
        end
    end

endmodule
