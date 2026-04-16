`timescale 1ns / 1ps

module n_modulo_counter_watch # (
    parameter N = 60,
    parameter TIME_SET = 0
) (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       en,
    input  wire       count_set,
    output reg  [6:0] count,
    output reg        tick
);
    localparam WIDTH = $clog2(N);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= TIME_SET;
            tick  <= 0;
        end else begin
            tick <= 0;  // en 내부로 들어가면 안됨
            if (en) begin
                if (count == N - 1) begin
                    count <= TIME_SET;
                    tick  <= 1;
                end else begin
                    count <= count + 1;
                end
            end
        end
    end

endmodule
