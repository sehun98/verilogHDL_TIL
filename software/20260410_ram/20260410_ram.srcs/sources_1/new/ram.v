`timescale 1ns / 1ps
// SDP RAM
// rst_n이 없는 이유
// BRAM inference
// 같은 주소를 동시에 쓰면?
// 같은 주소를 read/write 동시에 하면?
module ram (
    input wire clk,

    input wire we_a,
    input wire [7:0] waddr_a,
    input wire [7:0] wdata_a,
    input wire [7:0] raddr_a,
    output reg [7:0] rdata_a,

    input wire we_b,
    input wire [7:0] waddr_b,
    input wire [7:0] wdata_b,
    input wire [7:0] raddr_b,
    output reg [7:0] rdata_b
);

    reg [7:0] mem [0:255];

    always @(posedge clk) begin
        if (we_a)
            mem[waddr_a] <= wdata_a;
        rdata_a <= mem[raddr_a];
    end

    always @(posedge clk) begin
        if (we_b)
            mem[waddr_b] <= wdata_b;
        rdata_b <= mem[raddr_b];
    end

endmodule