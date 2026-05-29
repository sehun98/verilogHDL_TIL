`timescale 1ns / 1ps

module rv32i_cpu (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [31:0] instr_code,
    output wire [31:0] instr_addr,

    output wire [ 2:0] mem_mode,
    //output wire        data_mem_we,
    output logic W_REQ,
    output logic R_REQ,

    input logic READY,
    
    output wire [31:0] WDATA, // data_mem_wdata 
    output wire [31:0] ADDR, // data_mem_addr 
    input  wire [31:0] RDATA //data_mem_rdata
);

    wire [3:0] w_alu_control;  // 10bit -> 4bit
    wire [2:0] w_write_back_sel;
    wire w_alu_src_sel;
    wire w_reg_we;

    wire w_pc_branch;
    wire w_pc_jal;
    wire w_pc_jalr;

    wire w_pc_en;

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
        .WDATA(WDATA),
        .ADDR (ADDR),
        .RDATA(RDATA),

        .dec_rs1_en(dec_rs1_en),
        .dec_rs1_bubble(dec_rs1_bubble),
        .dec_rs2_en(dec_rs2_en),
        .dec_rs2_bubble(dec_rs2_bubble),
        .exe_alu_en(exe_alu_en),
        .exe_alu_bubble(exe_alu_bubble),
        .exe_rs2_en(exe_rs2_en),
        .exe_rs2_bubble(exe_rs2_bubble),
        .dec_imm_en(dec_imm_en),
        .dec_imm_bubble(dec_imm_bubble),
        .mem_rdata_en(mem_rdata_en),
        .mem_rdata_bubble(mem_rdata_bubble),
        .pc_en(w_pc_en),
        .exe_pc_next_en(exe_pc_next_en),
        .exe_pc_next_bubble(exe_pc_next_bubble),

        // pc
        .pc_branch(w_pc_branch),
        .pc_jal   (w_pc_jal),
        .pc_jalr  (w_pc_jalr)
    );

    rv32i_control_unit u2_rv32i_control_unit (
        .clk  (clk),
        .rst_n(rst_n),
        // instruction memory
        .instr_code(instr_code),

        // register file
        .alu_control   (w_alu_control),
        .write_back_sel(w_write_back_sel),
        .alu_src_sel   (w_alu_src_sel),
        .reg_we        (w_reg_we),

        // data memory
        .mem_mode   (mem_mode),
        //.data_mem_we(data_mem_we),

        .pc_en(w_pc_en),

        // pc
        .pc_branch(w_pc_branch),
        .pc_jal   (w_pc_jal),
        .pc_jalr  (w_pc_jalr)
    );
endmodule
