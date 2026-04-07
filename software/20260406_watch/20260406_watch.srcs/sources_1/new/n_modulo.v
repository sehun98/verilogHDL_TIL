`timescale 1ns / 1ps

module n_modulo #(
    parameter  N = 1000,
    localparam M = $clog2(N)
) (
    input wire clk,
    input wire rst_n,
    input wire count_tick,
    input wire sys_en,
    input wire clear,
    output reg tick,
    output reg [M-1:0] data_out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 0;
            tick <= 0;
        end else begin
            if (clear) begin
                data_out <= 0;
                tick <= 0;
            end else begin
                if (count_tick && sys_en) begin
                    if (data_out == N - 1) begin
                        data_out <= 0;
                        tick <= 1;
                    end else begin
                        data_out <= data_out + 1;
                        tick <= 0;
                    end
                end else begin
                    tick <= 0;
                end
            end
        end
    end

endmodule
