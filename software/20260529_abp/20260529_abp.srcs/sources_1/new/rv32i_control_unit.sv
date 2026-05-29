`timescale 1ns / 1ps
`include "define.vh"

module rv32i_control_unit (
    input wire clk,
    input wire rst_n,

    input wire READY, // from APB Master

    input wire [31:0] instr_code,

    output wire [3:0] alu_control,     // 10bit -> 4bit
    output wire       alu_src_sel,
    output wire [2:0] write_back_sel,
    output wire       reg_we,

    output wire [2:0] mem_mode,
    // output wire       data_mem_we,
    
    output logic W_REQ,
    output logic R_REQ,

    output wire pc_en,

    output wire pc_branch,
    output wire pc_jal,
    output wire pc_jalr
);
    wire [6:0] funct7;
    wire [2:0] funct3;
    wire [6:0] opcode;

    reg  [3:0] alu_control_reg;
    reg        alu_src_sel_reg;
    reg  [2:0] write_back_sel_reg;
    reg        reg_we_reg;

    reg  [2:0] mem_mode_reg;
    reg        READY_reg;

    reg        pc_branch_reg;
    reg        pc_jal_reg;
    reg        pc_jalr_reg;

    reg        pc_en_reg;

    reg R_REQ_reg;
    reg W_REQ_reg;

    assign R_REQ = R_REQ_reg;
    assign W_REQ = W_REQ_reg;

    assign funct7 = instr_code[31:25];
    assign funct3 = instr_code[14:12];
    assign opcode = instr_code[6:0];

    assign alu_control = alu_control_reg;
    assign alu_src_sel = alu_src_sel_reg;
    assign write_back_sel = write_back_sel_reg;
    assign reg_we = reg_we_reg;
    assign mem_mode = mem_mode_reg;
    assign READY = READY_reg;

    assign pc_branch = pc_branch_reg;
    assign pc_jal = pc_jal_reg;
    assign pc_jalr = pc_jalr_reg;

    assign pc_en = pc_en_reg;

    // [DEBUG]
    typedef enum logic [6:0] {
        DBG_B_TYPE = `B_TYPE,
        DBG_R_TYPE = `R_TYPE,
        DBG_S_TYPE = `S_TYPE,
        DBG_LOAD_I_TYPE = `LOAD_I_TYPE,
        DBG_ALU_I_TYPE = `ALU_I_TYPE,
        DBG_LUI_TYPE = `LUI_TYPE,
        DBG_AUIPC_TYPE = `AUIPC_TYPE,
        DBG_JAL_TYPE = `JAL_TYPE,
        DBG_JALR_TYPE = `JALR_TYPE
    } opcode_dbg_enum;

    opcode_dbg_enum opcode_dbg;

    typedef enum logic [2:0] {
        LOAD_ALU = 3'd0,
        LOAD_MEM,
        LOAD_IMM,
        AUIPC,
        PC_4
    } wirte_back_enum;

    typedef enum logic [2:0] {
        FETCH,
        DECODE,
        EXECUTE,
        MEM,
        WB
    } state_t;

    state_t c_state, n_state;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            c_state <= FETCH;
        end else begin
            c_state <= n_state;
        end
    end

    assign opcode_dbg = opcode_dbg_enum'(opcode);

    always_comb begin
        n_state = c_state;

        case (c_state)
            FETCH: begin
                n_state = DECODE;
            end
            DECODE: begin
                n_state = EXECUTE;
            end
            EXECUTE: begin
                case (opcode)
                    `R_TYPE, `ALU_I_TYPE, `B_TYPE, `LUI_TYPE, `JAL_TYPE, `JALR_TYPE, `AUIPC_TYPE : begin
                        n_state = FETCH;
                    end
                    `S_TYPE, `LOAD_I_TYPE: begin
                        n_state = MEM;
                    end
                endcase
            end
            MEM: begin
                if (opcode == `S_TYPE) begin
                    if(READY_reg) begin
                        n_state = FETCH;
                    end
                end else n_state = WB;
            end
            WB: begin
                if(READY_reg) begin
                n_state = FETCH;
                end
            end
        endcase
    end

    always_comb begin
        pc_en_reg = 0;
        alu_control_reg = 4'd0;
        alu_src_sel_reg = 1'b0;
        write_back_sel_reg = 3'b0;
        reg_we_reg = 1'b0;

        mem_mode_reg = 3'd0;
        READY_reg = 1'b0;

        pc_branch_reg = 1'b0;
        pc_jal_reg = 1'b0;
        pc_jalr_reg = 1'b0;

        W_REQ_reg = 0;
        R_REQ_reg = 0;

        case (c_state)
            FETCH: begin
                pc_en_reg = 1;
            end
            DECODE: begin

            end
            EXECUTE: begin
                case (opcode)
                    `R_TYPE: begin
                        reg_we_reg = 1;
                        alu_src_sel_reg = 0;
                        write_back_sel_reg = 3'b0;
                        alu_control_reg = {funct7[5], funct3};
                    end
                    `ALU_I_TYPE: begin
                        reg_we_reg = 1;
                        alu_src_sel_reg = 1;
                        write_back_sel_reg = 3'b0;
                        if (funct3 == 3'b101)
                            alu_control_reg = {funct7[5], funct3};
                        else alu_control_reg = {1'b0, funct3};
                    end
                    `B_TYPE: begin
                        pc_branch_reg   = 1;
                        alu_src_sel_reg = 0;
                        alu_control_reg = {1'b0, funct3};
                    end
                    `JAL_TYPE, `JALR_TYPE: begin
                        reg_we_reg = 1;
                        pc_jal_reg = 1;
                        if (opcode == `JAL_TYPE) begin
                            pc_jalr_reg = 0;
                        end else begin
                            pc_jalr_reg = 1;
                        end
                        write_back_sel_reg = 3'b100;
                    end
                    `LUI_TYPE, `AUIPC_TYPE: begin
                        reg_we_reg = 1;
                        if (opcode == `LUI_TYPE) write_back_sel_reg = 3'b010;
                        else write_back_sel_reg = 3'b011;
                    end
                    `S_TYPE, `LOAD_I_TYPE: begin
                        alu_src_sel_reg = 1;
                        alu_control_reg = `ADD;
                    end
                endcase
            end
            MEM: begin
                mem_mode_reg = funct3;
                if (opcode == `S_TYPE) W_REQ = 1'b1;
                else R_REQ = 1'b1;
            end
            WB: begin
                reg_we_reg = 1'b1;
                write_back_sel_reg = 1'b1;
            end
        endcase
    end

    /*
    // state 관리가 필요없음.
    always_comb begin
        alu_control_reg = 4'd0;
        alu_src_sel_reg = 1'b0;
        write_back_sel_reg = 3'b0;
        reg_we_reg = 1'b0;

        mem_mode_reg = 3'd0;
        data_mem_we_reg = 1'b0;

        pc_branch_reg = 1'b0;
        pc_jal_reg = 1'b0;
        pc_jalr_reg = 1'b0;
        case (opcode)
            `R_TYPE: begin
                alu_control_reg = {funct7[5], funct3};
                alu_src_sel_reg = 1'b0;
                write_back_sel_reg = LOAD_ALU;
                reg_we_reg = 1'b1;

                mem_mode_reg = 3'd0;
                data_mem_we_reg = 1'b0;

                pc_branch_reg = 1'b0;
                pc_jal_reg = 1'b0;
                pc_jalr_reg = 1'b0;
            end
            `S_TYPE: begin
                alu_control_reg = `ADD;
                alu_src_sel_reg = 1'b1;
                write_back_sel_reg = LOAD_ALU;
                reg_we_reg = 1'b0;

                mem_mode_reg = funct3;
                data_mem_we_reg = 1'b1;

                pc_branch_reg = 1'b0;
                pc_jal_reg = 1'b0;
                pc_jalr_reg = 1'b0;
            end
            `LOAD_I_TYPE: begin
                alu_control_reg = `ADD;
                alu_src_sel_reg = 1'b1;  // rs1 + imm
                write_back_sel_reg = LOAD_MEM;
                reg_we_reg = 1'b1;

                mem_mode_reg = funct3;
                data_mem_we_reg = 1'b0;

                pc_branch_reg = 1'b0;
                pc_jal_reg = 1'b0;
                pc_jalr_reg = 1'b0;
            end
            `ALU_I_TYPE: begin
                if (funct3 == 3'b101) begin
                    alu_control_reg = {funct7[5], funct3};
                end else begin
                    alu_control_reg = {1'b0, funct3};
                end
                alu_src_sel_reg = 1'b1;  // rs1 + imm
                write_back_sel_reg = LOAD_ALU;
                reg_we_reg = 1'b1;

                mem_mode_reg = 3'd0;
                data_mem_we_reg = 1'b0;

                pc_branch_reg = 1'b0;
                pc_jal_reg = 1'b0;
                pc_jalr_reg = 1'b0;
            end
            `B_TYPE: begin
                alu_control_reg = {1'b0, funct3};
                alu_src_sel_reg = 1'b0;
                write_back_sel_reg = LOAD_ALU;
                reg_we_reg = 1'b0;

                mem_mode_reg = 3'd0;
                data_mem_we_reg = 1'b0;

                pc_branch_reg = 1'b1;
                pc_jal_reg = 1'b0;
                pc_jalr_reg = 1'b0;
            end
            `LUI_TYPE, `AUIPC_TYPE: begin
                alu_control_reg = 4'b0;
                if (opcode == `AUIPC_TYPE) begin
                    write_back_sel_reg = AUIPC;
                end else begin
                    write_back_sel_reg = LOAD_IMM;
                end
                alu_src_sel_reg = 1'b0;
                reg_we_reg = 1'b1;

                mem_mode_reg = 3'd0;
                data_mem_we_reg = 1'b0;

                pc_branch_reg = 1'b0;
                pc_jal_reg = 1'b0;
                pc_jalr_reg = 1'b0;
            end
            `JAL_TYPE: begin
                alu_control_reg = 4'b0;
                alu_src_sel_reg = 1'b0;
                write_back_sel_reg = PC_4;
                reg_we_reg = 1'b1;

                mem_mode_reg = 3'd0;
                data_mem_we_reg = 1'b0;

                pc_branch_reg = 1'b0;
                pc_jal_reg = 1'b1;
                pc_jalr_reg = 1'b0;
            end
            `JALR_TYPE: begin
                alu_control_reg = 4'b0;
                write_back_sel_reg = PC_4;
                alu_src_sel_reg = 1'b0;
                reg_we_reg = 1'b1;

                mem_mode_reg = 3'd0;
                data_mem_we_reg = 1'b0;

                pc_branch_reg = 1'b0;
                pc_jal_reg = 1'b1;
                pc_jalr_reg = 1'b1;
            end
        endcase
    end
    */
endmodule
