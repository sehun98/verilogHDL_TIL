`timescale 1ns / 1ps
`include "define.vh"

module data_memory (
    input  wire        clk,
    input  wire [31:0] data_mem_data,
    input  wire [31:0] data_mem_addr,
    input  wire [ 2:0] mem_mode,
    input  wire        data_mem_we,
    output wire [31:0] data_read_mem_data
);
    initial begin


    end

    logic [31:0] data_mem[0:255];
    always_ff @(posedge clk) begin
        if(data_mem_we) begin
            case(mem_mode) 
                // 0100 1000 1100 04812 -> 0001 0010 0011 01234
                `SW : data_mem[data_mem_addr[31:2]] <= data_mem_data;
                // 0100 1000 1100 04812 -> 0010 0100 1010 02468
                `SH : data_mem[data_mem_addr[31:1]] <= data_mem_data[15:0];
                // 0100 1000 1100 04812 -> 0100 1000 1100 04812
                `SB : data_mem[data_mem_addr] <= data_mem_data[7:0];
            endcase
        end
    end
assign data_read_mem_data = data_mem[data_mem_addr[31:2]];
endmodule
