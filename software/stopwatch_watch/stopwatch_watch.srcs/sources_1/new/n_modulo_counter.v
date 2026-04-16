`timescale 1ns / 1ps

module n_modulo_counter #(
    parameter N = 60
) (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       en,
    input  wire       clear,
    input  wire       mode,
    output reg  [6:0] count,
    output reg        tick
);
    localparam WIDTH = $clog2(N);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n || clear) begin
            count <= 0;
            tick  <= 0;
        end else begin
            tick <= 0;  // en 내부로 들어가면 안됨
            if (en) begin
                if (!mode) begin
                    if (count == N - 1) begin
                        count <= 0;
                        tick  <= 1;
                    end else begin
                        count <= count + 1;
                    end
                end else begin
                    if (count == 0) begin
                        count <= N - 1;
                        tick  <= 1;
                    end else begin
                        count <= count - 1;
                    end
                end
            end
        end
    end

endmodule
