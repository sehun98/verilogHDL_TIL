`timescale 1ns / 1ps

// 1 cycle delay pipo
module pipo (
    input wire clk,
    input wire rst_n,
    input wire [7:0] d,
    output wire [7:0] q
);
    // 8bit 126 size mem
    reg [7:0] mem;

    integer i;

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            mem <= 8'b0;
        end else begin
            mem <= d;
        end        
    end

    assign q = mem;
endmodule
