`timescale 1ns / 1ps

module uart_baud_rate_acc #(
    parameter CLOCK_FREQ_HZ = 100_000_000,
    parameter BAUD_RATE     = 115200
) (
    input  wire clk,
    input  wire rst_n,
    output reg  baud_tick
);

    localparam CNT_WIDTH = $clog2(CLOCK_FREQ_HZ);
    localparam BAUD_RATE_16 = BAUD_RATE * 16;

    // CNT_WIDTH-1
    reg [CNT_WIDTH:0] cnt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt       <= {(CNT_WIDTH + 1) {1'b0}};
            baud_tick <= 1'b0;
        end else begin
            if (cnt + BAUD_RATE_16 >= CLOCK_FREQ_HZ) begin
                baud_tick <= 1'b1;
                cnt       <= cnt + BAUD_RATE_16 - CLOCK_FREQ_HZ;
            end else begin
                baud_tick <= 1'b0;
                cnt       <= cnt + BAUD_RATE_16;
            end
        end
    end
endmodule

module uart_baud_rate_cnt #(
    parameter CLOCK_FREQ_HZ = 100_000_000,
    parameter BAUD_RATE = 115200
) (
    input  wire clk,
    input  wire rst_n,
    output reg  baud_tick
);

    localparam BAUD_RATE_16 = BAUD_RATE * 16;
    localparam CNT = CLOCK_FREQ_HZ / BAUD_RATE_16;
    localparam CNT_WIDTH = $clog2(CNT);

    // CNT_WIDTH-1
    reg [CNT_WIDTH-1:0] cnt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt       <= {CNT_WIDTH{1'b0}};
            baud_tick <= 1'b0;
        end else begin
            if (cnt == CNT - 1) begin
                baud_tick <= 1'b1;
                cnt       <= 1'b0;
            end else begin
                baud_tick <= 1'b0;
                cnt <= cnt + 1'b1;
            end
        end
    end
endmodule
