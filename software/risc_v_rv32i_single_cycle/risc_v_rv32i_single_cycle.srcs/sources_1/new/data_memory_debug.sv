`timescale 1ns / 1ps
`include "define.vh"

module data_memory_debug (
    input  wire        clk,
    input  wire [31:0] data_mem_wdata,
    input  wire [31:0] data_mem_addr,
    input  wire [ 2:0] mem_mode,
    input  wire        data_mem_we,
    output wire [31:0] data_mem_rdata
);
    reg [31:0] mem [0:63]; // 저장 공간 수
    reg [31:0] data_mem_addr_reg;

    assign data_mem_rdata = data_mem_addr_reg;

    integer i = 0;

    initial begin
        for(i = 0; i <64; i=i+1) begin
            mem[i] = 32'd0;
        end
    end

    always_ff @(posedge clk) begin
        if (data_mem_we) begin
            case (mem_mode)
                `SW: begin
                    mem[data_mem_addr[31:2]] <= data_mem_wdata;
                end

                `SH: begin
                    case (data_mem_addr[1])
                        1'b0: mem[data_mem_addr[31:2]][15:0]  <= data_mem_wdata[15:0];
                        1'b1: mem[data_mem_addr[31:2]][31:16] <= data_mem_wdata[15:0];
                    endcase
                end

                `SB: begin
                    case (data_mem_addr[1:0])
                        2'b00: mem[data_mem_addr[31:2]][7:0]   <= data_mem_wdata[7:0];
                        2'b01: mem[data_mem_addr[31:2]][15:8]  <= data_mem_wdata[7:0];
                        2'b10: mem[data_mem_addr[31:2]][23:16] <= data_mem_wdata[7:0];
                        2'b11: mem[data_mem_addr[31:2]][31:24] <= data_mem_wdata[7:0];
                    endcase
                end
            endcase
        end
    end

    always_comb begin
        data_mem_addr_reg = 32'd0;

        case (mem_mode)
            `LW: begin
                data_mem_addr_reg = mem[data_mem_addr[31:2]];
            end

            `LH: begin
                case (data_mem_addr[1])
                    1'b0: data_mem_addr_reg = {{16{mem[data_mem_addr[31:2]][15]}}, mem[data_mem_addr[31:2]][15:0]};
                    1'b1: data_mem_addr_reg = {{16{mem[data_mem_addr[31:2]][31]}}, mem[data_mem_addr[31:2]][31:16]};
                endcase
            end

            `LB: begin
                case (data_mem_addr[1:0])
                    2'b00: data_mem_addr_reg = {{24{mem[data_mem_addr[31:2]][7]}},  mem[data_mem_addr[31:2]][7:0]};
                    2'b01: data_mem_addr_reg = {{24{mem[data_mem_addr[31:2]][15]}}, mem[data_mem_addr[31:2]][15:8]};
                    2'b10: data_mem_addr_reg = {{24{mem[data_mem_addr[31:2]][23]}}, mem[data_mem_addr[31:2]][23:16]};
                    2'b11: data_mem_addr_reg = {{24{mem[data_mem_addr[31:2]][31]}}, mem[data_mem_addr[31:2]][31:24]};
                endcase
            end

            `LBU: begin
                case (data_mem_addr[1:0])
                    2'b00: data_mem_addr_reg = {24'd0, mem[data_mem_addr[31:2]][7:0]};
                    2'b01: data_mem_addr_reg = {24'd0, mem[data_mem_addr[31:2]][15:8]};
                    2'b10: data_mem_addr_reg = {24'd0, mem[data_mem_addr[31:2]][23:16]};
                    2'b11: data_mem_addr_reg = {24'd0, mem[data_mem_addr[31:2]][31:24]};
                endcase
            end

            `LHU: begin
                case (data_mem_addr[1])
                    1'b0: data_mem_addr_reg = {16'd0, mem[data_mem_addr[31:2]][15:0]};
                    1'b1: data_mem_addr_reg = {16'd0, mem[data_mem_addr[31:2]][31:16]};
                endcase
            end
        endcase
    end
endmodule
