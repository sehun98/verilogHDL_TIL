`timescale 1ns / 1ps

module top_rv32i_soc_debug (
    input  wire        clk,
    input  wire        rst_n,
    // data memory
    output wire [ 2:0] mem_mode_debug,
    output wire        data_mem_we_debug,
    output wire [31:0] data_mem_wdata_debug,
    output wire [31:0] data_mem_addr_debug,
    output wire [31:0] data_mem_rdata_debug,

    // branch
    output wire b_taken_debug,
    // program counter
    output wire [31:0] instr_addr_debug,

    // register file
    output wire [31:0] write_back_out_debug,
    output wire [31:0] rs1_debug,
    output wire        reg_we_debug,
    output wire [31:0] instr_code_debug
);


    instruction_memory_debug u1_instruction_memory (
        .instr_addr(instr_addr_debug),
        .instr_code(instr_code_debug)
    );

    rv32i_cpu_debug u2_rv32i_cpu (
        .clk             (clk),
        .rst_n           (rst_n),
        .instr_code      (instr_code_debug),
        .instr_addr_debug(instr_addr_debug),
        .mem_mode        (mem_mode_debug),
        .data_mem_we     (data_mem_we_debug),
        .data_mem_wdata  (data_mem_wdata_debug),
        .data_mem_addr   (data_mem_addr_debug),
        .data_mem_rdata  (data_mem_rdata_debug),

        // debug
        .b_taken_debug       (b_taken_debug),
        .write_back_out_debug(write_back_out_debug),
        .rs1_debug           (rs1_debug),
        .reg_we_debug        (reg_we_debug)
    );

    data_memory_debug u3_data_memory (
        .clk           (clk),
        .mem_mode      (mem_mode_debug),
        .data_mem_we   (data_mem_we_debug),
        .data_mem_wdata(data_mem_wdata_debug),
        .data_mem_addr (data_mem_addr_debug),
        .data_mem_rdata(data_mem_rdata_debug)
    );
endmodule
