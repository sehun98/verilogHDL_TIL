`timescale 1ns / 1ps
`include "define.vh"

module data_memory (
    input  wire        clk,
    input  wire [31:0] data_wdata,
    input  wire [31:0] data_addr,
    input  wire [ 2:0] mem_mode,
    input  wire        data_we,
    output wire [31:0] data_rdata
);

    logic [31:0] mem [0:255];

    wire [31:0] word_data;
    wire [1:0]  byte_off;

    logic [31:0] data_rdata_reg;

    assign word_data = mem[data_addr[31:2]];
    assign byte_off  = data_addr[1:0];

    always_ff @(posedge clk) begin
        if (data_we) begin
            case (mem_mode)
                `SW: begin
                    mem[data_addr[31:2]] <= data_wdata;
                end

                `SH: begin
                    case (byte_off[1])
                        1'b0: mem[data_addr[31:2]][15:0]  <= data_wdata[15:0];
                        1'b1: mem[data_addr[31:2]][31:16] <= data_wdata[15:0];
                    endcase
                end

                `SB: begin
                    case (byte_off)
                        2'b00: mem[data_addr[31:2]][7:0]   <= data_wdata[7:0];
                        2'b01: mem[data_addr[31:2]][15:8]  <= data_wdata[7:0];
                        2'b10: mem[data_addr[31:2]][23:16] <= data_wdata[7:0];
                        2'b11: mem[data_addr[31:2]][31:24] <= data_wdata[7:0];
                    endcase
                end
            endcase
        end
    end

    always_comb begin
        case (mem_mode)
            `LW: begin
                data_rdata_reg = word_data;
            end

            `LH: begin
                case (byte_off[1])
                    1'b0: data_rdata_reg = {{16{word_data[15]}}, word_data[15:0]};
                    1'b1: data_rdata_reg = {{16{word_data[31]}}, word_data[31:16]};
                endcase
            end

            `LB: begin
                case (byte_off)
                    2'b00: data_rdata_reg = {{24{word_data[7]}},  word_data[7:0]};
                    2'b01: data_rdata_reg = {{24{word_data[15]}}, word_data[15:8]};
                    2'b10: data_rdata_reg = {{24{word_data[23]}}, word_data[23:16]};
                    2'b11: data_rdata_reg = {{24{word_data[31]}}, word_data[31:24]};
                endcase
            end

            default: begin
                data_rdata_reg = 32'd0;
            end
        endcase
    end

    assign data_rdata = data_rdata_reg;

endmodule