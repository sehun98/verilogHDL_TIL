`timescale 1ns / 1ps
`define MEMSIZE 4

module ram (
    input  wire clk,
    input  wire [`MEMSIZE-1:0] addr,
    input  wire en,
    input  wire [7:0] wdata,
    output wire [7:0] rdata
);
    // 1111_1111 2^8 
    reg [7:0] mem [0:2**`MEMSIZE-1];
    reg [7:0] rdata_reg;

    assign rdata = rdata_reg;

    always_ff @(posedge clk) begin
        if(en) begin
            mem[addr] <= wdata;
        end else begin
            rdata_reg <= mem[addr];
        end
    end
endmodule


