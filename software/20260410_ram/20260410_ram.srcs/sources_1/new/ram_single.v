`timescale 1ns / 1ps

module ram_single (
    input  wire clk,
    
    input  wire we,
    input  wire [7:0]  waddr,
    input  wire [7:0] wdata,
    input  wire [7:0] raddr,
    output reg [7:0] rdata
);
    reg [7:0] mem [0:255];

    always @(posedge clk) begin
        if(we) begin
            mem[waddr] <= wdata;
        end
        rdata <= mem[raddr];
    end

endmodule