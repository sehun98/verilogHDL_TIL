`timescale 1ns / 1ps

module register_file (
    input  logic       clk,

    input  logic [7:0] wdata,
    input  logic [3:0] waddr,

    output logic [7:0] rdata,
    input  logic [3:0] raddr,
    
    input  logic       we
);
    logic [7:0] mem[0:15];

    always_ff @(posedge clk) begin 
        if(we) begin
            mem[waddr] <= wdata;
        end
    end

    assign rdata = mem[raddr];
endmodule
