`timescale 1ns / 1ps

module register_file #(
    parameter  DEPTH     = 16,
    localparam BIT_WIDTH = $clog2(DEPTH)
) (
    input wire                 clk,
    input wire [BIT_WIDTH-1:0] waddr,
    input wire [BIT_WIDTH-1:0] raddr,
    input wire [          7:0] wdata,
    output wire [          7:0] rdata,
    input wire                 we
);
    // 2**BIT_WIDTH -1 
    reg [7:0] mem[0:DEPTH-1];

    always @(posedge clk) begin
        if (we) begin
            mem[waddr] <= wdata;
        end
    end

    assign rdata = mem[raddr];

endmodule