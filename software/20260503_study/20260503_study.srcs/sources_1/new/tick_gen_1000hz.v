`timescale 1ns / 1ps

module tick_gen_1000hz #(
    parameter CLOCK_FREQ_HZ = 100_000_000,
    parameter HZ = 1000
)(
    input wire clk,
    input wire rst_n,
    output reg tick
    );

    localparam CNT = CLOCK_FREQ_HZ / HZ;
    localparam CNT_WIDTH = $clog2(CNT);

    reg [CNT_WIDTH-1:0] cnt;

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            cnt <= {CNT_WIDTH{1'b0}};
            tick <= 1'b0;
        end else begin
            if(cnt==CNT-1) begin
                tick <= 1'b1;
                cnt <= {CNT_WIDTH{1'b0}};
            end else begin
                tick <= 1'b0;
                cnt <= cnt + 1'b1;
            end
        end
    end
endmodule
