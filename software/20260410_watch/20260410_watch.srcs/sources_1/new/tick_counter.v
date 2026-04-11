`timescale 1ns / 1ps

// 0~9999
module tick_counter #(
    parameter TICK_COUNT = 10000,
    localparam TICK_COUNT_WIDTH = $clog2(TICK_COUNT)
) (
    input wire clk,
    input wire rst_n,
    input wire mode_sel,
    input wire tick,
    output reg [TICK_COUNT_WIDTH-1:0] tick_count
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tick_count <= {TICK_COUNT_WIDTH{1'b0}};
        end else begin
            if (tick) begin
                if(!mode_sel) begin
                    if (tick_count == TICK_COUNT - 1) begin
                        tick_count <= 0;
                    end else begin
                        tick_count <= tick_count + 1'b1;
                    end
                end else begin
                    if (tick_count == 0) begin
                        tick_count <= TICK_COUNT - 1'b1;
                    end else begin
                        tick_count <= tick_count - 1'b1;
                    end
                end
            end
        end
    end

endmodule
