`timescale 1ns / 1ps

module uart_baud_rate #(
    parameter CLOCK_FREQ_HZ = 100_000_000,
    parameter BAUD_RATE = 115200
) (
    input  wire clk,
    input  wire rst_n,
    output wire  baud_tick
);
    reg baud_tick_reg;

    localparam BAUD_RATE_16 = BAUD_RATE * 16;
    localparam CNT = CLOCK_FREQ_HZ / BAUD_RATE_16;
    localparam CNT_WIDTH = $clog2(CNT);

    // CNT_WIDTH-1
    reg [CNT_WIDTH-1:0] cnt;
    
    assign baud_tick = baud_tick_reg;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt       <= {CNT_WIDTH{1'b0}};
            baud_tick_reg <= 1'b0;
        end else begin
            if (cnt == CNT - 1) begin
                cnt       <= {CNT_WIDTH{1'b0}};
                baud_tick_reg <= 1'b1;
            end else begin
                cnt <= cnt + 1'b1;
                baud_tick_reg <= 1'b0;
            end
        end
    end
endmodule
