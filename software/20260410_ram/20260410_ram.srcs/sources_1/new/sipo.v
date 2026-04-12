`timescale 1ns / 1ps

module sipo (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       d,
    input  wire       shift_en,
    output wire [7:0] q
);
    reg [7:0] mem;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            mem <= 8'b0;
        else if (shift_en)
            mem <= {d, mem[7:1]};
    end

    assign q = mem;
endmodule
