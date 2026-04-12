`timescale 1ns / 1ps

// multi cycle delay 1bit siso
module siso (
    input wire clk,
    input wire rst_n,
    input wire d,
    output wire q
);
    reg [7:0] mem;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mem <= 8'b0;
        end else begin
            mem <= {d, mem[7:1]};
        end
    end

    assign q = mem[0];

endmodule
