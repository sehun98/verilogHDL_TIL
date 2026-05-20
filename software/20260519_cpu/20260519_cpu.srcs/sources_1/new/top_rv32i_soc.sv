`timescale 1ns / 1ps

module top_rv32i_soc (
    input wire clk,
    input wire rst_n
);
    wire [31:0] w_instr_addr;
    wire [31:0] w_instr_code;

    wire [31:0] w_data_mem_data;
    wire [31:0] w_data_mem_addr;
    wire [2:0] w_mem_mode;
    wire w_data_mem_we;
    wire [31:0] w_data_read_mem_data;

    instruction_memory u1_instruction_memory (
        .instr_addr(w_instr_addr),
        .instr_code(w_instr_code)
    );

    rv32i_cpu u2_rv32i_cpu (
        .clk               (clk),
        .rst_n             (rst_n),
        .instr_code        (w_instr_code),
        .instr_addr        (w_instr_addr),
        .mem_mode          (w_mem_mode),
        .data_mem_we       (w_data_mem_we),
        .data_mem_data     (w_data_mem_data),
        .data_mem_addr     (w_data_mem_addr),
        .data_read_mem_data(w_data_read_mem_data)
    );

    data_memory u3_data_memory (
        .clk               (clk),
        .data_mem_data     (w_data_mem_data),
        .data_mem_addr     (w_data_mem_addr),
        .mem_mode          (w_mem_mode),
        .data_mem_we       (w_data_mem_we),
        .data_read_mem_data(w_data_read_mem_data)
    );
endmodule
