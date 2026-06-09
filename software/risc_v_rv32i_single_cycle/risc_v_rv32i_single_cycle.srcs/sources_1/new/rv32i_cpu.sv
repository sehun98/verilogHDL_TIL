`timescale 1ns / 1ps

module rv32i_cpu (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [31:0] instr_code,
    output wire [31:0] instr_addr,

    output wire [ 2:0] mem_mode,
    output wire        data_mem_we,
    output wire [31:0] data_mem_wdata,
    output wire [31:0] data_mem_addr,
    input  wire [31:0] data_mem_rdata
);

    wire [3:0] w_alu_control;  // 10bit -> 4bit
    wire [2:0] w_write_back_sel;
    wire w_alu_src_sel;
    wire w_reg_we;

    wire w_pc_branch;
    wire w_pc_jal;
    wire w_pc_jalr;

    rv32i_datapath u1_rv32i_datapath (
        .clk  (clk),
        .rst_n(rst_n),

        // instruction memory
        .instr_code(instr_code),
        .instr_addr(instr_addr),

        // register file
        .alu_control   (w_alu_control),
        .write_back_sel(w_write_back_sel),
        .alu_src_sel   (w_alu_src_sel),
        .reg_we        (w_reg_we),

        // data memory
        .data_mem_wdata(data_mem_wdata),
        .data_mem_addr (data_mem_addr),
        .data_mem_rdata(data_mem_rdata),

        // pc
        .pc_branch(w_pc_branch),
        .pc_jal   (w_pc_jal),
        .pc_jalr  (w_pc_jalr)
    );

    rv32i_control_unit u2_rv32i_control_unit (
        // instruction memory
        .instr_code(instr_code),

        // register file
        .alu_control   (w_alu_control),
        .write_back_sel(w_write_back_sel),
        .alu_src_sel   (w_alu_src_sel),
        .reg_we        (w_reg_we),

        // data memory
        .mem_mode   (mem_mode),
        .data_mem_we(data_mem_we),

        // pc
        .pc_branch(w_pc_branch),
        .pc_jal   (w_pc_jal),
        .pc_jalr  (w_pc_jalr)
    );
endmodule
