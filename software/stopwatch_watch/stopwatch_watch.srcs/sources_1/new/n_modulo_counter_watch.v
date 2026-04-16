`timescale 1ns / 1ps

module n_modulo_counter_watch #(
    parameter N        = 60,
    parameter TIME_SET = 0,
    parameter WIDTH    = $clog2(N)
) (
    input  wire             clk,
    input  wire             rst_n,
    input  wire             en,
    input  wire             set_en,
    input  wire [WIDTH-1:0] set_value,
    output reg  [WIDTH-1:0] count,
    output reg              tick
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= TIME_SET[WIDTH-1:0];
            tick  <= 1'b0;
        end else begin
            tick <= 1'b0;

            if (set_en) begin
                count <= set_value;
            end else if (en) begin
                if (count == N - 1) begin
                    count <= TIME_SET[WIDTH-1:0];
                    tick  <= 1'b1;
                end else begin
                    count <= count + 1'b1;
                end
            end
        end
    end

endmodule