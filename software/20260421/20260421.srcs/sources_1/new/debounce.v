`timescale 1ns / 1ps

module debounce #(
    parameter integer CLK_FREQ_HZ = 100_000_000,
    parameter integer DEBOUNCE_MS = 20
)(
    input  wire clk,
    input  wire rst_n,
    input  wire din,
    output reg  dout
);

localparam integer MAX_COUNT = (CLK_FREQ_HZ / 1000) * DEBOUNCE_MS;
localparam integer CNT_WIDTH = $clog2(MAX_COUNT);

reg sync_ff1, sync_ff2;
reg [CNT_WIDTH-1:0] cnt;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        sync_ff1 <= 1'b0;
        sync_ff2 <= 1'b0;
    end else begin
        sync_ff1 <= din;
        sync_ff2 <= sync_ff1;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        cnt  <= 'd0;
        dout <= 1'b0;
    end else begin
        if (sync_ff2 == dout) begin
            cnt <= 'd0;
        end else begin
            if (cnt < MAX_COUNT - 1) begin
                cnt <= cnt + 1'b1;
            end else begin
                cnt  <= 'd0;
                dout <= sync_ff2;
            end
        end
    end
end

endmodule