`timescale 1ns / 1ps

`include "define.vh"

module risc_v_32i ();
endmodule

module risc_v_32i_datapath ();

endmodule

module register_file (
    input wire clk,
    // control unit
    input wire we,

    // instruction memory
    input wire [4:0] raddr0,
    input wire [4:0] raddr1,
    input wire [4:0] waddr,

    // alu
    output wire [31:0] rdata0,
    output wire [31:0] rdata1,
    input  wire [31:0] wdata
);
    reg [31:0] mem[1:31];

    initial begin
        for (int i = 1; i < 32; i = i + 1) begin
            mem[i] = i;
        end
    end

    always_ff @(posedge clk) begin
        if (we) begin
            mem[waddr] = wdata;
        end
    end

    assign rdata0 = (raddr0 == 32'd0) ? 32'd0 : mem[raddr0];
    assign rdata1 = (raddr1 == 32'd0) ? 32'd0 : mem[raddr1];
endmodule

module alu(
    input wire [31:0] a,
    input wire [31:0] b,
    input wire [9:0] alu_control,
    output wire [31:0] alu_result
);
    reg [31:0] alu_result_reg;

    assign alu_result = alu_result_reg;
    always_comb begin
        case(alu_control)
            'ADD : alu_result_reg = a + b;
        endcase
    end
endmodule
