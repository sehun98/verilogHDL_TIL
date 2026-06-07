`timescale 1ns / 1ps

module top_rv32i_soc (
    input wire clk,
    input wire rst_n
);
    wire [31:0] w_instr_addr;
    wire [31:0] w_instr_code;

    wire [ 2:0] w_mem_mode;
    wire        w_data_mem_we;
    wire [31:0] WDATA;
    wire [31:0] ADDR;
    wire [31:0] RDATA;

    instruction_memory u1_instruction_memory (
        .instr_addr(w_instr_addr),
        .instr_code(w_instr_code)
    );

    rv32i_cpu u2_rv32i_cpu (
        .clk       (clk),
        .rst_n     (rst_n),
        .instr_code(w_instr_code),
        .instr_addr(w_instr_addr),
        .mem_mode  (w_mem_mode),
        //.data_mem_we   (w_data_mem_we),
        .WDATA     (WDATA),
        .ADDR      (ADDR),
        .RDATA     (RDATA)
    );

    /*
    data_memory u3_data_memory (
        .clk           (clk),
        .data_mem_wdata(w_data_mem_wdata),
        .data_mem_addr (w_data_mem_addr),
        .mem_mode      (w_mem_mode),
        .data_mem_we   (w_data_mem_we),
        .data_mem_rdata(w_data_mem_rdata)
    );
    */

    logic [31:0] ADDR;
    logic [31:0] WDATA;
    logic        R_REQ;
    logic        W_REQ;
    logic [31:0] RDATA;
    logic        READY;
    logic [31:0] PADDR;
    logic [31:0] PWDATA;
    logic        PENABLE;
    logic        PWRITE;
    logic        PSEL0;
    logic        PSEL1;
    logic        PSEL2;
    logic        PSEL3;
    logic        PSEL4;
    logic        PREADY0;
    logic        PREADY1;
    logic        PREADY2;
    logic        PREADY3;
    logic        PREADY4;
    logic [31:0] PRDATA0;
    logic [31:0] PRDATA1;
    logic [31:0] PRDATA2;
    logic [31:0] PRDATA3;
    logic [31:0] PRDATA4;

    logic        PCLK;
    logic        PRESET;
    APB_master u3_APB_master (
        .PCLK  (clk),
        .PRESET(rst_n),
        .ADDR  (ADDR),
        .WDATA (WDATA),
        .W_REQ (W_REQ),
        .R_REQ (R_REQ),
        .RDATA (RDATA),
        .READY (READY),

        .PSEL0  (PSEL0),
        .PREADY0(PREADY0),
        .PRDATA0(PRDATA0),
        .*
    );

    APB_slave u4_APB_slave (
        //BUS Global signal
        .PCLK  (clk),
        .PSEL  (PSEL0),
        .PREADY(PREADY0),
        .PRDATA(PRDATA0),
        .*
    );

endmodule
