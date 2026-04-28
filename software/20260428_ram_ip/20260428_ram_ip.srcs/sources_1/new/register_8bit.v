`timescale 1ns / 1ps

module register_8it (
    input wire clk,
    input wire rst_n,
    input wire [7:0] d,
    output wire [7:0] q
);

    reg [7:0] q_reg;

    assign q = q_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q_reg <= 8'b0;
        end else begin
            q_reg <= d;
        end
    end
endmodule

module register_8it_2 (
    input wire clk,
    input wire rst_n,
    input wire [7:0] d,
    output reg [7:0] q
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q <= 8'b0;
        end else begin
            q <= d;
        end
    end
endmodule

