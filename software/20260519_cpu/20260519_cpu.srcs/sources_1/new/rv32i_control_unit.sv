`timescale 1ns / 1ps
`include "define.vh"

module rv32i_control_unit (
    input  wire [31:0] instr_code,
    output reg         register_file_we,
    output reg         mux_src_sel,
    output reg  [ 2:0] mem_mode,
    output reg         data_mem_we,
    output reg register_file_src_sel,
    output reg  [ 3:0] alu_control        // 10bit -> 4bit
);
    wire [6:0] funct7;
    wire [2:0] funct3;
    wire [6:0] opcode;

    assign funct7 = instr_code[31:25];
    assign funct3 = instr_code[14:12];
    assign opcode = instr_code[6:0];

    // [DEBUG]
    typedef enum logic [6:0] { DBG_R_TYPE = `R_TYPE, DBG_S_TYPE = `S_TYPE, DBG_LOAD_I_TYPE = `LOAD_I_TYPE, DBG_ALU_I_TYPE = `ALU_I_TYPE} opcode_dbg_enum;
    opcode_dbg_enum opcode_dbg;
    assign opcode_dbg = opcode_dbg_enum'(opcode);

    // state 관리가 필요없음.
    always_comb begin
        register_file_we = 1'b0;
        alu_control = 32'd0;
        mux_src_sel = 1'b0;
        mem_mode = 3'd0;
        data_mem_we = 1'b0;
        register_file_src_sel = 1'b0;
        case (opcode)
            `R_TYPE: begin
                register_file_we = 1'b1;
                mux_src_sel = 1'b0;
                mem_mode = 3'd0;
                data_mem_we = 1'b0;
                alu_control = {funct7[5], funct3};
                register_file_src_sel = 1'b0;

                /*
            case({funct7[5],funct3})
                `ADD : alu_control = `ADD;
                `SUB : alu_control = `SUB;
                `SLL : alu_control = `SLL;
                `SLT : alu_control = `SLT;
                `SLTU : alu_control = `SLTU;
                `XOR : alu_control = `XOR;
                `SRL : alu_control = `SRL;
                `SRA : alu_control = `SRA;
                `OR : alu_control = `OR;
                `AND : alu_control = `AND;
            endcase
            */
            end
            `S_TYPE: begin
                register_file_we = 1'b0;
                mux_src_sel = 1'b1;
                mem_mode = funct3;
                data_mem_we = 1'b1;
                alu_control = `ADD;
                register_file_src_sel = 1'b0;
            end
            `LOAD_I_TYPE: begin
                register_file_we = 1'b1;
                mux_src_sel = 1'b1; // rs1 + imm
                mem_mode = funct3;
                data_mem_we = 1'b0;
                alu_control = `ADD;
                register_file_src_sel = 1'b1;
            end
            `ALU_I_TYPE: begin
                register_file_we = 1'b1;
                mux_src_sel = 1'b1; // rs1 + imm
                mem_mode = 3'd0;
                data_mem_we = 1'b0;
                if(funct3==3'b101) begin
                    alu_control = {funct7[5], funct3};
                end else begin
                    alu_control = {1'b0, funct3};
                end
                register_file_src_sel = 1'b0;
            end
        endcase
    end
endmodule
