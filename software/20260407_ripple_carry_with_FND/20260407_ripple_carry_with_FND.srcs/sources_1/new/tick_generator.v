`timescale 1ns / 1ps

module tick_generator (
    input  wire clk,
    input  wire rst_n,
    output reg  tick_1ms
);
    reg [15:0] count;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= 0;
            tick_1ms <= 0;
        end else begin
            if (count == 50_000-1) begin
                count <= 0;
                tick_1ms <= ~tick_1ms;
            end else begin
                count <= count + 1;
            end
        end
    end

endmodule
