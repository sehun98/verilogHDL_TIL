`timescale 1ns / 1ps

module rv32i_cpu (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [31:0] instr_code,
    output wire [31:0] instr_addr
);
wire w_register_file_we;
wire [9:0] w_alu_control;

rv32i_datapath u1_rv32i_datapath (
    .clk(clk),
    .rst_n(rst_n),
    .instr_code(instr_code),
    .register_file_we(w_register_file_we),
    .alu_control(w_alu_control),
    .instr_addr(instr_addr)
);

rv32i_control_unit u2_rv32i_control_unit (
    .funct7(instr_code[31:25]),
    .funct3(instr_code[14:12]),
    .opcode(instr_code[6:0]),
    .register_file_we(w_register_file_we),
    .alu_control(w_alu_control)
);

endmodule
