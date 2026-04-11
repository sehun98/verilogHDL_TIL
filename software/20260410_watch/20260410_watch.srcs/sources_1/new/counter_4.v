`timescale 1ns / 1ps

module counter_4 (
    input wire clk,
    input wire rst_n,
    output reg [1:0] digit_sel
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            digit_sel <= 2'd0;
        end else begin
            digit_sel <= digit_sel + 2'd1;
        end
    end

endmodule
