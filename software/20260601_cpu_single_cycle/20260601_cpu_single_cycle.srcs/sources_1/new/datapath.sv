`timescale 1ns / 1ps

module datapath(

    );
endmodule

module register_file(
    input wire clk,
    input wire [4:0] raddr1,
    input wire [4:0] raddr2,
    input wire [4:0] waddr,
    input wire [31:0] wdata,
    input wire reg_we,
    output wire [31:0] rdata1,
    output wire [31:0] rdata2
);
    reg [31:0] mem[0:2**5-1];

    always_ff @(posedge clk) begin
        if(reg_we) begin
            mem[waddr] <= wdata;
        end
    end

    assign rdata1 = (raddr1==32'd0) ? 32'd0 : mem[raddr1];
    assign rdata2 = (raddr2==32'd0) ? 32'd0 : mem[raddr2];
endmodule

`define ADD 5'b0_0_000
`define SUB 5'b1_0_000
`define BEQ 3'b000

module alu(
    input wire [31:0] a,
    input wire [31:0] b,
    input wire [4:0] alu_control, // {funct[5], funct[0], funct3[2:0]}
    output wire b_taken,
    output wire [31:0] result
);
    reg [31:0] alu_add;
    reg [31:0] alu_sub;
    reg b_taken_reg;
    reg [31:0] result_reg;

    assign alu_add = a + b;
    assign alu_sub = a - b;

    assign b_taken = b_taken_reg;
    assign result = result_reg;

    always_comb begin
        case(alu_control)
            `ADD : result_reg = alu_add;
            `SUB : result_reg = alu_sub;
        endcase
    end

    always_comb begin
        case(alu_control[2:0])
            `BEQ : b_taken_reg = (a == b);
        endcase
    end
endmodule