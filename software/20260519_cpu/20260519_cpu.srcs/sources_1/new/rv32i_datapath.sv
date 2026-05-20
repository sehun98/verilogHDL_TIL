`timescale 1ns / 1ps
`include "define.vh"

module rv32i_datapath (
    input  wire         clk,
    input  wire         rst_n,
    input  wire  [31:0] instr_code,
    input  wire         register_file_we,
    input  logic [ 3:0] alu_control,       // 10bit -> 4bit
    input reg         mux_src_sel,
    output wire  [31:0] instr_addr,
    output wire [31:0] data_mem_data,
    output wire [31:0] data_mem_addr,
    input wire register_file_src_sel,
    input  wire [31:0] data_read_mem_data
);
    wire [31:0] w_rs1;
    wire [31:0] w_rs2;
    wire [31:0] w_alu_result;
    wire [31:0] w_mux2to1_result;
    wire [31:0] w_immediate_code;
    wire [31:0] w_register_file_src_mux_out;

    assign data_mem_addr = w_alu_result;
    assign data_mem_data = w_rs2;

    rv32i_register_file u1_rv32i_register_file (
        .clk(clk),

        // control unit
        .raddr1          (instr_code[19:15]),
        .raddr2          (instr_code[24:20]),
        .waddr           (instr_code[11:7]),
        .register_file_we(register_file_we),

        // alu
        .wdata (w_register_file_src_mux_out),
        .rdata1(w_rs1),
        .rdata2(w_rs2)
    );

    rv32i_alu u2_rv32i_alu (
        .rs1        (w_rs1),
        .rs2        (w_mux2to1_result),
        .alu_control(alu_control),
        .alu_result (w_alu_result)
    );

    immediate_generator u3_immediate_generator (
        .instr_code(instr_code),
        .immediate_code(w_immediate_code)
    );

    mux2to1 u4_mux2to1 (
        .in0(w_rs2),
        .in1(w_immediate_code),
        .mux_src_sel(mux_src_sel),
        .mux_result(w_mux2to1_result)
    );

    rv32i_program_counter u5_rv32i_program_counter (
        .clk   (clk),
        .rst_n (rst_n),
        .pc_in (instr_addr),
        .pc_out(instr_addr)
    );

    mux2to1 u5_mux2to1 (
        .in0(w_alu_result),
        .in1(data_read_mem_data),
        .mux_src_sel(register_file_src_sel),
        .mux_result(w_register_file_src_mux_out)
    );

endmodule

module rv32i_register_file (
    input wire clk,

    // instruction memory
    input wire [4:0] raddr1,  // 32
    input wire [4:0] raddr2,
    input wire [4:0] waddr,

    // control unit
    input wire register_file_we,

    // feedback
    input wire [31:0] wdata,

    // alu
    output wire [31:0] rdata1,
    output wire [31:0] rdata2
);
    reg [31:0] mem[1:31];

    initial begin
        for (int i = 0; i < 32; i = i + 1) begin
            mem[i] = i;
        end
        mem[31] = 32'hFFFF_FFFF;
    end

    always_ff @(posedge clk) begin
        if (register_file_we) begin
            mem[waddr] <= wdata;
        end
    end

    assign rdata1 = (raddr1 == 5'd0) ? 32'd0 : mem[raddr1];
    assign rdata2 = (raddr2 == 5'd0) ? 32'd0 : mem[raddr2];
endmodule

module rv32i_alu (
    input  wire [31:0] rs1,
    input  wire [31:0] rs2,
    input  wire [ 3:0] alu_control,  // 10bit -> 4bit
    output wire [31:0] alu_result
);
    reg [31:0] alu_result_reg;

    always_comb begin
        alu_result_reg = 32'd0;
        case (alu_control)
            `ADD: alu_result_reg = rs1 + rs2;
            `SUB: alu_result_reg = rs1 - rs2;
            `SLL: alu_result_reg = rs1 << rs2[4:0];  // 2^5 =32 a<<b; 
            `SLT:
            alu_result_reg = ($signed(rs1) < $signed(rs2)) ? 32'd1 : 32'd0;
            `SLTU:
            alu_result_reg = ($unsigned(rs1) < $unsigned(rs2)) ? 32'd1 :
                32'd0;  // zero-extention
            `XOR: alu_result_reg = rs1 ^ rs2;
            `SRL: alu_result_reg = rs1 >> rs2[4:0];  // a>>b;
            `SRA:
            alu_result_reg = $signed(rs1) >>>
                rs2[4:0];  // a>>b; // msb-extention
            `OR: alu_result_reg = rs1 | rs2;
            `AND: alu_result_reg = rs1 & rs2;
        endcase
    end
    assign alu_result = alu_result_reg;
endmodule

module rv32i_program_counter (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [31:0] pc_in,
    output wire [31:0] pc_out
);
    reg [31:0] mem;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mem <= 32'd0;
        end else begin
            mem <= pc_in + 32'd4;
        end
    end
    assign pc_out = mem;
endmodule

module immediate_generator(
    input wire [31:0] instr_code,
    output wire [31:0] immediate_code
);
    reg [31:0] immediate_code_reg;

    assign immediate_code = immediate_code_reg;

    always_comb begin
        immediate_code_reg = 32'd0;
        case(instr_code[6:0])
            `S_TYPE : immediate_code_reg = {{20{instr_code[31]}},instr_code[31:25],instr_code[11:7]};
            `B_TYPE : immediate_code_reg = {{20{instr_code[31]}},instr_code[31],instr_code[7],instr_code[30:25],instr_code[11:8]};
            `LOAD_I_TYPE, `ALU_I_TYPE : immediate_code_reg = {{20{instr_code[31]}},instr_code[31:20]};
            `U_TYPE : immediate_code_reg = {{12{instr_code[31]}},instr_code[31:12]};
            `J_TYPE : immediate_code_reg = {{12{instr_code[31]}},instr_code[31],instr_code[19:12],instr_code[13],instr_code[30:14]};
        endcase
    end
endmodule

module mux2to1(
    input wire[31:0] in0,
    input wire[31:0] in1,
    input wire mux_src_sel,
    output wire [31:0] mux_result
);
    assign mux_result = mux_src_sel ? in1 : in0;
endmodule