`timescale 1ns / 1ps

module sram (
    input  logic       clk,
    input  logic [7:0] addr,
    input  logic [7:0] wdata,
    output logic [7:0] rdata,
    input  logic       we
);

    // 2^8
    logic [7:0] mem[0:255];

    always_ff @(posedge clk) begin
        if (we) begin
            mem[addr] <= wdata;
        end
    end
    assign rdata = mem[addr];
endmodule
