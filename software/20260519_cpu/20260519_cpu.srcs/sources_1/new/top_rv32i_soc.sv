`timescale 1ns / 1ps

module top_rv32i_soc (
    input wire clk,
    input wire rst_n
);
    wire [31:0] w_instr_addr;
    wire [31:0] w_instr_code;

    instruction_memory u1_instruction_memory (
        .instr_addr(w_instr_addr),
        .instr_code(w_instr_code)
    );

    rv32i_cpu u2_rv32i_cpu (
        .clk(clk),
        .rst_n(rst_n),
        .instr_code(w_instr_code),
        .instr_addr(w_instr_addr)
    );
endmodule
