`timescale 1ns / 1ps

module rv32i_cpu (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [31:0] instr_code,
    output wire [31:0] instr_addr,
    output wire [ 2:0] mem_mode,
    output wire        data_mem_we,
    output wire [31:0] data_mem_data,
    output wire [31:0] data_mem_addr,
    input  wire [31:0] data_read_mem_data
);
    wire w_register_file_we;
    wire [3:0] w_alu_control;  // 10bit -> 4bit

    rv32i_datapath u1_rv32i_datapath (
        .clk                  (clk),
        .rst_n                (rst_n),
        .instr_code           (instr_code),
        .register_file_we     (w_register_file_we),
        .alu_control          (w_alu_control),
        .mux_src_sel          (mux_src_sel),
        .instr_addr           (instr_addr),
        .data_mem_data        (data_mem_data),
        .data_mem_addr        (data_mem_addr),
        .register_file_src_sel(register_file_src_sel),
        .data_read_mem_data   (data_read_mem_data)
    );

    rv32i_control_unit u2_rv32i_control_unit (
        .instr_code      (instr_code),
        .register_file_we(w_register_file_we),
        .alu_control     (w_alu_control),
        .mux_src_sel     (mux_src_sel),
        .mem_mode        (mem_mode),
        .register_file_src_sel(register_file_src_sel),
        .data_mem_we     (data_mem_we)
    );
endmodule
