`timescale 1ns / 1ps

module rv32i_cpu_debug (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [31:0] instr_code,
    output wire [31:0] instr_addr_debug,

    output wire [ 2:0] mem_mode,
    output wire        data_mem_we,
    output wire [31:0] data_mem_wdata,
    output wire [31:0] data_mem_addr,
    input  wire [31:0] data_mem_rdata,

    output wire        b_taken_debug,
    output wire [31:0] write_back_out_debug,
    output wire [31:0] rs1_debug,
    output wire        reg_we_debug
);
    wire [3:0] w_alu_control;  // 10bit -> 4bit
    wire [2:0] w_write_back_sel;
    wire w_alu_src_sel;

    wire w_pc_branch;
    wire w_pc_jal;
    wire w_pc_jalr;

    rv32i_datapath_debug u1_rv32i_datapath (
        .clk  (clk),
        .rst_n(rst_n),

        // instruction memory
        .instr_code     (instr_code),
        .instr_addr_debug(instr_addr_debug),

        // register file
        .alu_control   (w_alu_control),
        .write_back_sel(w_write_back_sel),
        .alu_src_sel   (w_alu_src_sel),
        .reg_we        (reg_we_debug),

        // data memory
        .data_mem_wdata(data_mem_wdata),
        .data_mem_addr (data_mem_addr),
        .data_mem_rdata(data_mem_rdata),

        // pc
        .pc_branch(w_pc_branch),
        .pc_jal   (w_pc_jal),
        .pc_jalr  (w_pc_jalr),

        // debug
        .b_taken_debug(b_taken_debug),
        .write_back_out_debug(write_back_out_debug),
        .rs1_debug(rs1_debug)
    );

    rv32i_control_unit u2_rv32i_control_unit (
        // instruction memory
        .instr_code(instr_code),

        // register file
        .alu_control   (w_alu_control),
        .write_back_sel(w_write_back_sel),
        .alu_src_sel   (w_alu_src_sel),
        .reg_we        (reg_we_debug),

        // data memory
        .mem_mode   (mem_mode),
        .data_mem_we(data_mem_we),

        // pc
        .pc_branch(w_pc_branch),
        .pc_jal   (w_pc_jal),
        .pc_jalr  (w_pc_jalr)
    );
endmodule
