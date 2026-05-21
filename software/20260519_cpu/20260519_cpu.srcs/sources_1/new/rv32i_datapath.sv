`timescale 1ns / 1ps
`include "define.vh"
// 명령어, 블록도
module rv32i_datapath (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [31:0] instr_code,
    input  wire        register_file_we,
    input  wire [ 3:0] alu_control,            // 10bit -> 4bit
    input  wire        mux_src_sel,
    output wire [31:0] instr_addr,
    output wire [31:0] data_mem_data,
    output wire [31:0] data_mem_addr,
    input  wire [ 2:0] register_file_src_sel,
    input  wire [31:0] data_read_mem_data,
    input  wire        branch,
    input  wire        jal,
    input  wire        jalr
);
    wire [31:0] w_rs1;
    wire [31:0] w_rs2;
    wire [31:0] w_alu_result;
    wire [31:0] w_mux2to1_result;
    wire [31:0] w_immediate_code;
    wire [31:0] w_write_back_out;

    wire [31:0] w_pc_imm;
    wire [31:0] w_pc_4;

    wire w_b_taken;

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
        .wdata (w_write_back_out),
        .rdata1(w_rs1),
        .rdata2(w_rs2)
    );

    rv32i_alu u2_rv32i_alu (
        .rs1        (w_rs1),
        .rs2        (w_mux2to1_result),
        .alu_control(alu_control),
        .alu_result (w_alu_result),
        .b_taken    (w_b_taken)
    );

    immediate_generator u3_immediate_generator (
        .instr_code(instr_code),
        .immediate_code(w_immediate_code)
    );

    assign w_mux2to1_result = mux_src_sel ? w_immediate_code : w_rs2;
    /*
    mux2to1 u4_mux2to1 (
        .in0(w_rs2),
        .in1(w_immediate_code),
        .mux_src_sel(mux_src_sel),
        .mux_result(w_mux2to1_result)
    );
    */

    rv32i_program_counter u5_rv32i_program_counter (
        .clk   (clk),
        .rst_n (rst_n),

        //.immediate_code (w_immediate_code), // pc_alu_result
        .pc_in(pc_in),
        .immediate_code (w_immediate_code), // pc_alu_result
        .rs1(w_rs1),

        
        .b_taken(w_b_taken),
        .branch(branch),
        .jal(jal),
        .jalr(jalr),

        .pc_imm(w_pc_imm),
        .pc_4(w_pc_4),

        .pc_out(instr_addr)
    );

    //assign w_register_file_src_mux_out = (register_file_src_sel) ? data_read_mem_data : w_alu_result;
    /*
    mux2to1 u6_mux2to1 (
        .in0(w_alu_result),
        .in1(data_read_mem_data),
        .mux_src_sel(register_file_src_sel),
        .mux_result(w_register_file_src_mux_out)
    );
    */
    write_back u6_write_back (
        .in0(w_alu_result),
        .in1(data_read_mem_data),
        .in2(immediate_code),
        .in3(w_pc_imm),
        .in4(w_pc_4),
        .write_back_sel(register_file_src_sel),
        .write_back_result(w_write_back_out)
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
    input wire [31:0] rs1,
    input wire [31:0] rs2,
    input wire [3:0] alu_control,  // 10bit -> 4bit
    output wire [31:0] alu_result,
    output wire b_taken
);
    reg [31:0] alu_result_reg;
    reg b_taken_reg;

    always_comb begin
        alu_result_reg = 32'd0;
        case (alu_control)
            // R-type : Rd = Rs1 + Rs2
            // I-ALU-type : Rd = Rs1 + Imm
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

    always_comb begin
        b_taken_reg = 1'd0;
        case (alu_control[2:0])  // 0000 -> 000
            // branch-type : PC += imm
            `BEQ:  b_taken_reg = (rs1 == rs2);
            `BNE:  b_taken_reg = (rs1 != rs2);
            `BLT:  b_taken_reg = ($signed(rs1) < $signed(rs2));
            `BGE:  b_taken_reg = ($signed(rs1) >= $signed(rs2));
            `BLTU: b_taken_reg = ($unsigned(rs1) < $unsigned(rs2));
            `BGEU: b_taken_reg = ($unsigned(rs1) >= $unsigned(rs2));
        endcase
    end
    assign alu_result = alu_result_reg;
    assign b_taken = b_taken_reg;
endmodule

module rv32i_program_counter (
    input wire clk,
    input wire rst_n,

    input wire [31:0] pc_in,  // branch target offset 또는 branch target
    input wire [31:0] immediate_code,  // branch target offset 또는 branch target
    input wire [31:0] rs1,

    input wire b_taken,
    input wire branch,
    input wire jal,
    input wire jalr,

    output wire [31:0] pc_imm,
    output wire [31:0] pc_4,
    output wire [31:0] pc_out
);
    reg [31:0] pc_reg;
    reg [31:0] pc_next;
    reg [31:0] pc_mux_result;

    assign pc_out = pc_reg;

    assign pc_imm = immediate_code + pc_jalr;
    assign pc_4 = pc_in + 32'd4;

    assign pc_next = (jalr|jal|(branch & b_taken)) ? (pc_imm) : (pc_4);
    assign pc_jalr = jalr ? rs1 : pc_in;


    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) pc_reg <= 32'd0;
        else pc_reg <= pc_next;
    end
endmodule

module immediate_generator (
    input  wire [31:0] instr_code,
    output wire [31:0] immediate_code
);
    reg [31:0] immediate_code_reg;
    assign immediate_code = immediate_code_reg;
    always_comb begin
        immediate_code_reg = 32'd0;
        case (instr_code[6:0])
            `S_TYPE:
            immediate_code_reg = {
                {20{instr_code[31]}}, instr_code[31:25], instr_code[11:7]
            };
            `LOAD_I_TYPE, `ALU_I_TYPE, `JALR_TYPE:
            immediate_code_reg = {{20{instr_code[31]}}, instr_code[31:20]};
            `B_TYPE:
            immediate_code_reg = {
                {20{instr_code[31]}},
                instr_code[7],
                instr_code[30:25],
                instr_code[11:8],
                1'b0
            };
            `LUI_TYPE, `AUIPC_TYPE: immediate_code_reg = {instr_code[31:12], {12{1'b0}}};
            `JAL_TYPE:
            immediate_code_reg = {
                {11{instr_code[31]}},  // 11
                instr_code[31],  // 1 <- 20
                instr_code[19:12],  // 8 <- 19~12
                instr_code[20],  // 1 <- 11
                instr_code[30:21],  // 10 <- 10~1
                1'b0  // 1
            };
        endcase
    end
endmodule

module mux2to1 (
    input wire [31:0] in0,
    input wire [31:0] in1,
    input wire mux_src_sel,
    output wire [31:0] mux_result
);
    assign mux_result = mux_src_sel ? in1 : in0;
endmodule

module write_back (
    input  wire [31:0] in0,
    input  wire [31:0] in1,
    input  wire [31:0] in2,
    input  wire [31:0] in3,
    input  wire [31:0] in4,
    input  wire [ 2:0] write_back_sel,
    output wire [31:0] write_back_result
);
    reg [31:0] write_back_result_reg;

    always_comb begin
        case (write_back_sel)
            3'd0: write_back_result_reg = in0; // load  alu
            3'd1: write_back_result_reg = in1; // load data memory
            3'd2: write_back_result_reg = in2; // load LUI : load upper imm
            3'd3: write_back_result_reg = in3; // load Add upper Imm to PC
            3'd4: write_back_result_reg = in4; // load JAL, JARL : PC + 4
            default: write_back_result_reg = in0;
        endcase
    end
    assign write_back_result = write_back_result_reg;
endmodule
