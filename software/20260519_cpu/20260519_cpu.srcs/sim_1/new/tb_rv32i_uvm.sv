`timescale 1ns / 1ps
`include "define.vh"

interface rv32i_interface ();
    logic        clk;
    logic        rst_n;

    logic [ 2:0] mem_mode_debug;
    logic        data_mem_we_debug;
    logic [31:0] data_mem_wdata_debug;
    logic [31:0] data_mem_addr_debug;
    logic [31:0] data_mem_rdata_debug;

    logic        b_taken_debug;
    logic [31:0] instr_addr_debug;
    logic [31:0] write_back_out_debug;
    logic [31:0] rs1_debug;
    logic        reg_we_debug;
    logic [31:0] instr_code_debug;
endinterface

class transaction;
    rand bit        [ 6:0] funct7;
    rand bit        [ 4:0] rs2;
    rand bit        [ 4:0] rs1;
    rand bit        [ 2:0] funct3;
    rand bit        [ 4:0] rd;
    rand bit        [ 6:0] opcode;
    rand bit signed [31:0] imm;

    bit             [31:0] instr;

    bit             [ 2:0] mem_mode_debug;
    bit                    data_mem_we_debug;
    bit             [31:0] data_mem_wdata_debug;
    bit             [31:0] data_mem_addr_debug;
    bit             [31:0] data_mem_rdata_debug;

    bit                    b_taken_debug;
    bit             [31:0] instr_addr_debug;
    bit             [31:0] write_back_out_debug;
    bit             [31:0] rs1_debug;
    bit                    reg_we_debug;
    bit             [31:0] instr_code_debug;

    constraint solve_order_c {
        solve opcode before funct3;
        solve funct3 before funct7;
        solve opcode before rs2;
        solve opcode before rs1;
        solve funct3 before imm;
    }

    constraint opcode_c {
        /*
        // Phase 1: 데이터 확인
        opcode dist {
            `R_TYPE      := 30,
            `ALU_I_TYPE  := 30,
            `LOAD_I_TYPE := 20,
            `S_TYPE      := 15,
            `LUI_TYPE    := 5
        };
*/
        // Phase 2: 전체 확인
        opcode dist {
            `R_TYPE      := 10,
            `ALU_I_TYPE  := 10,
            `LOAD_I_TYPE := 10,
            `S_TYPE      := 10,
            `LUI_TYPE    := 5,
            `AUIPC_TYPE  := 5,
            `B_TYPE      := 25,
            `JAL_TYPE    := 20,
            `JALR_TYPE   := 5
        };
    }
    constraint funct3_c {
        if (opcode == `R_TYPE || opcode == `ALU_I_TYPE) {
            funct3 inside {3'b000,
            3'b001, 
            3'b010, 3'b011, 3'b100,
            3'b101, 
            3'b110, 3'b111};
        } else
        if (opcode == `S_TYPE) {
            funct3 inside {`SB, `SH, `SW};
        } else
        if (opcode == `LOAD_I_TYPE) {
            funct3 inside {`LB, `LH, `LW, `LBU, `LHU};
        } else
        if (opcode == `B_TYPE) {
            funct3 inside {`BEQ, `BNE, `BLT, `BGE, `BLTU, `BGEU};
        } else {
        if (opcode == `JALR_TYPE || opcode == `JAL_TYPE || opcode == `AUIPC_TYPE || opcode == `LUI_TYPE) {
            funct3 == 3'b000;
        } else
            funct3 == 3'b000;
        }
    }

    constraint funct7_c {
        if (opcode == `R_TYPE && (funct3 == 3'b000 || funct3 == 3'b101)) {
            funct7 inside {7'b000_0000, 7'b010_0000};
        } else
        if (opcode == `ALU_I_TYPE && funct3 == 3'b101) {
            funct7 inside {7'b000_0000, 7'b010_0000};
        } else {
            funct7 == 7'b000_0000;
        }
    }

    constraint rs2_c {
        if (opcode != `R_TYPE && opcode != `B_TYPE && opcode != `S_TYPE) {
            rs2 == 5'b0_0000;
        }
    }

    constraint rs1_c {
        if(opcode == `JAL_TYPE || opcode == `AUIPC_TYPE || opcode == `LUI_TYPE) {
            rs1 == 5'b0_0000;
        }
    }

    constraint rd_c {
        if (opcode == `B_TYPE || opcode == `S_TYPE) {
            rd == 5'b0_0000;
        }
    }

    constraint imm_c {
        if (opcode == `ALU_I_TYPE) {
            imm inside {[-2048 : 2047]}; // imm[11:0] 2^12 = 4096
        } else if (opcode == `LOAD_I_TYPE) {
            rs1 == 5'd0;
            imm inside {[0:255]}; // data memory size * 4
            if (funct3 == `LW) {
                imm[1:0] == 2'b00;   // word aligned
            } else if (funct3 == `LH || funct3 == `LHU) {
                imm[0] == 1'b0;      // halfword aligned
            } else {
                // LB, LBU
                // byte access라 alignment 제한 없음
            }
        } else if (opcode == `S_TYPE) {
            rs1 == 5'd0;
            imm inside {[0:255]}; // data memory size * 4
            if (funct3 == `SW) {
                imm[1:0] == 2'b00;   // word aligned
            } else if (funct3 == `SH) {
                imm[0] == 1'b0;      // halfword aligned
            } else {
                // SB
                // byte access라 alignment 제한 없음
            }
        } else if (opcode inside {`LUI_TYPE, `AUIPC_TYPE}) { // imm[31:12] 사용, 하위 0
            imm[11:0] == 12'b0;
        } else if (opcode == `B_TYPE) { // pc = pc + imm
            imm inside {[-64 : 64]};
            imm[0] == 1'b0;
        } else if (opcode == `JAL_TYPE) { // pc = pc + imm
            imm inside {[-64 : 64]}; // instruction memory 64
            imm[0] == 1'b0;
        } else if (opcode == `JALR_TYPE) { // pc = rs1 + imm
            rs1 == 5'd0;              // x0 기준 jump
            imm inside {[0 : 252]};   // instruction memory 범위 안
            imm[1:0] == 2'b00;        // 4-byte aligned
        } else {
            imm == 32'd0;
        }
    }
endclass

class generator;
    transaction tr;

    function new();

    endfunction

    integer i   = 1;
    integer fd;

    task run(ref logic [31:0] gen2scb_instr_mem[0:(`INSTR_MEM_WORDS)-1]);
        fd = $fopen("instruction_code.mem", "w");
        if (fd != 0) begin
            $display("[SUCCESS] file open");
        end
        //dut.u1_instruction_memory.instruction_rom[0] = 32'h4000_0113;
        $fdisplay(fd, "%08h", 32'h10000113);
        gen2scb_instr_mem[0] = 32'h10000113;

        tr = new();
        for (i = 1; i < (`INSTR_MEM_WORDS); i = i + 1) begin
            assert (tr.randomize())
            else $error("randomize failed");

            if (tr.opcode == `R_TYPE) begin
                tr.instr = {
                    tr.funct7, tr.rs2, tr.rs1, tr.funct3, tr.rd, tr.opcode
                };
            end else if (tr.opcode == `B_TYPE) begin
                tr.instr = {
                    tr.imm[12],
                    tr.imm[10:5],
                    tr.rs2,
                    tr.rs1,
                    tr.funct3,
                    tr.imm[4:1],
                    tr.imm[11],
                    tr.opcode
                };
            end else if (tr.opcode == `S_TYPE) begin
                tr.instr = {
                    tr.imm[11:5],
                    tr.rs2,
                    tr.rs1,
                    tr.funct3,
                    tr.imm[4:0],
                    tr.opcode
                };
            end else if (tr.opcode == `JALR_TYPE || tr.opcode == `LOAD_I_TYPE) begin
                tr.instr = {tr.imm[11:0], tr.rs1, tr.funct3, tr.rd, tr.opcode};
            end else if (tr.opcode == `ALU_I_TYPE) begin
                if (tr.funct3 == 3'b001 || tr.funct3 == 3'b101) begin
                    // SLLI, SRLI, SRAI
                    tr.instr = {
                        tr.funct7,
                        tr.imm[4:0],
                        tr.rs1,
                        tr.funct3,
                        tr.rd,
                        tr.opcode
                    };
                end else begin
                    // ADDI, SLTI, XORI ...
                    tr.instr = {
                        tr.imm[11:0], tr.rs1, tr.funct3, tr.rd, tr.opcode
                    };
                end
            end else if (tr.opcode == `LUI_TYPE || tr.opcode == `AUIPC_TYPE) begin
                tr.instr = {tr.imm[31:12], tr.rd, tr.opcode};
            end else if (tr.opcode == `JAL_TYPE) begin
                tr.instr = {
                    tr.imm[20],
                    tr.imm[10:1],
                    tr.imm[11],
                    tr.imm[19:12],
                    tr.rd,
                    tr.opcode
                };
            end
            $fdisplay(fd, "%08h", tr.instr);
            gen2scb_instr_mem[i] = tr.instr;
            //$display("%08h", tr.instr[i]);
        end

        $fclose(fd);
    endtask
endclass

class monitor;
    transaction tr;
    mailbox #(transaction) mon2drv_mbox;
    virtual rv32i_interface v_rv32i_if;

    function new(virtual rv32i_interface _v_rv32i_if,
                 mailbox#(transaction) _mon2drv_mbox);
        v_rv32i_if   = _v_rv32i_if;
        mon2drv_mbox = _mon2drv_mbox;
    endfunction

    task run(int cnt);
        repeat (cnt) begin
            tr = new();
            @(posedge v_rv32i_if.clk);
            #1;
            tr.mem_mode_debug = v_rv32i_if.mem_mode_debug;
            tr.data_mem_we_debug = v_rv32i_if.data_mem_we_debug;
            tr.data_mem_wdata_debug = v_rv32i_if.data_mem_wdata_debug;
            tr.data_mem_addr_debug = v_rv32i_if.data_mem_addr_debug;
            tr.data_mem_rdata_debug = v_rv32i_if.data_mem_rdata_debug;

            tr.b_taken_debug = v_rv32i_if.b_taken_debug;
            tr.instr_addr_debug = v_rv32i_if.instr_addr_debug;
            tr.write_back_out_debug = v_rv32i_if.write_back_out_debug;
            tr.rs1_debug = v_rv32i_if.rs1_debug;
            tr.reg_we_debug = v_rv32i_if.reg_we_debug;
            tr.instr_code_debug = v_rv32i_if.instr_code_debug;

            mon2drv_mbox.put(tr);
            //$display("[%t] dut.instr_code = %08h", $time, tr.instr_code_debug);
        end
    endtask
endclass

class scoreboard;
    transaction tr;
    mailbox #(transaction) mon2drv_mbox;

    logic [31:0] gen2scb_instr_mem[0:(`INSTR_MEM_WORDS)-1];

    logic [31:0] expect_register_file[0:31];
    logic [31:0] expect_data_memory[0:63];

    logic [31:0] expect_result;

    logic [6:0] opcode;
    logic [6:0] funct7;
    logic [4:0] rs2;
    logic [4:0] rs1;
    logic [2:0] funct3;
    logic [4:0] rd;

    logic [31:0] imm_i;

    logic [31:0] expect_data_mem_wdata;
    logic expect_data_mem_we;
    logic [2:0] expect_mem_mode;
    logic [31:0] expect_data_mem_addr;

    // ===============================================
    logic [31:0] imm_b;
    logic [31:0] imm_u;
    logic [31:0] imm_j;
    logic expect_b_taken;
    // ===============================================

    integer TOTAL_cnt_total = 0;
    integer TOTAL_cnt_pass = 0;
    integer TOTAL_cnt_fail = 0;

    integer i = 0;
    integer j = 0;

    integer OPCODE_cnt_total = 0;
    integer OPCODE_cnt_pass = 0;
    integer OPCODE_cnt_fail = 0;

    integer R_TYPE_cnt_total = 0;
    integer R_TYPE_cnt_pass = 0;
    integer R_TYPE_cnt_fail = 0;

    integer ALU_I_TYPE_cnt_total = 0;
    integer ALU_I_TYPE_cnt_pass = 0;
    integer ALU_I_TYPE_cnt_fail = 0;

    integer S_TYPE_cnt_total = 0;
    integer S_TYPE_cnt_pass = 0;
    integer S_TYPE_cnt_fail = 0;

    integer LOAD_I_TYPE_cnt_total = 0;
    integer LOAD_I_TYPE_cnt_pass = 0;
    integer LOAD_I_TYPE_cnt_fail = 0;

    integer B_TYPE_cnt_total = 0;
    integer B_TYPE_cnt_pass = 0;
    integer B_TYPE_cnt_fail = 0;


    integer LUI_TYPE_cnt_total = 0;
    integer LUI_TYPE_cnt_pass = 0;
    integer LUI_TYPE_cnt_fail = 0;


    integer AUIPC_TYPE_cnt_total = 0;
    integer AUIPC_TYPE_cnt_pass = 0;
    integer AUIPC_TYPE_cnt_fail = 0;


    integer JAL_TYPE_cnt_total = 0;
    integer JAL_TYPE_cnt_pass = 0;
    integer JAL_TYPE_cnt_fail = 0;


    integer JALR_TYPE_cnt_total = 0;
    integer JALR_TYPE_cnt_pass = 0;
    integer JALR_TYPE_cnt_fail = 0;

    integer SLTI_cnt_total = 0;
    integer ADDI_cnt_total = 0;
    integer SLTIU_cnt_total = 0;
    integer XORI_cnt_total = 0;
    integer ORI_cnt_total = 0;
    integer ANDI_cnt_total = 0;
    integer SLLI_cnt_total = 0;
    integer SRLI_cnt_total = 0;
    integer SRAI_cnt_total = 0;

    integer ADD_cnt_total = 0;
    integer SUB_cnt_total = 0;
    integer SLL_cnt_total = 0;
    integer SLT_cnt_total = 0;
    integer SLTU_cnt_total = 0;
    integer XOR_cnt_total = 0;
    integer SRL_cnt_total = 0;
    integer SRA_cnt_total = 0;
    integer OR_cnt_total = 0;
    integer AND_cnt_total = 0;

    integer SB_cnt_total = 0;
    integer SH_cnt_total = 0;
    integer SW_cnt_total = 0;

    integer LB_cnt_total = 0;
    integer LH_cnt_total = 0;
    integer LW_cnt_total = 0;
    integer LBU_cnt_total = 0;
    integer LHU_cnt_total = 0;

    integer BEQ_cnt_total = 0;
    integer BNE_cnt_total = 0;
    integer BLT_cnt_total = 0;
    integer BGE_cnt_total = 0;
    integer BLTU_cnt_total = 0;
    integer BGEU_cnt_total = 0;

    logic [31:0] expect_pc_next;

    function new(ref logic [31:0] _gen2scb_instr_mem[0:(`INSTR_MEM_WORDS)-1],
                 mailbox#(transaction) _mon2drv_mbox);
        for (i = 0; i < (`INSTR_MEM_WORDS); i = i + 1) begin
            gen2scb_instr_mem[i] = _gen2scb_instr_mem[i];
            //$display("%08h", gen2scb_instr_mem[i]);
        end
        for (int i = 0; i < 32; i++) begin
            expect_register_file[i] = 32'd0;
        end

        for (int i = 0; i < 64; i++) begin
            expect_data_memory[i] = 32'd0;
        end

        mon2drv_mbox = _mon2drv_mbox;
    endfunction

    task compare(transaction tr);
        funct7          = gen2scb_instr_mem[tr.instr_addr_debug[31:2]][31:25];
        rs2             = gen2scb_instr_mem[tr.instr_addr_debug[31:2]][24:20];
        rs1             = gen2scb_instr_mem[tr.instr_addr_debug[31:2]][19:15];
        funct3          = gen2scb_instr_mem[tr.instr_addr_debug[31:2]][14:12];
        rd              = gen2scb_instr_mem[tr.instr_addr_debug[31:2]][11:7];
        opcode          = gen2scb_instr_mem[tr.instr_addr_debug[31:2]][6:0];

        expect_mem_mode = funct3;

        OPCODE_cnt_total++;
        //$display("[SCB][%t] gen2scb_instr_mem[%d] = %08h, dut.instr_code = %08h", $time, j, gen2scb_instr_mem[j], tr.instr_code_debug);
        // opcode comparate
        if (gen2scb_instr_mem[tr.instr_addr_debug[31:2]][6:0] == tr.instr_code_debug[6:0]) begin
            OPCODE_cnt_pass++;
        end else begin
            OPCODE_cnt_fail++;
        end

        // register file comparate
        case (tr.instr_code_debug[6:0])
            // funct7[31:25], rs2[24:20], rs1[19:15], funct3[14:2], rd[11:7], opcode[6:0]
            `R_TYPE: begin
                R_TYPE_cnt_total++;
                case ({
                    funct7[5], funct3
                })
                    `ADD: begin
                        ADD_cnt_total++;
                        expect_result = expect_register_file[rs1] + expect_register_file[rs2]; // ADD
                    end
                    `SUB: begin
                        SUB_cnt_total++;
                        expect_result = expect_register_file[rs1] - expect_register_file[rs2]; // SUB
                    end
                    `SLL: begin
                        SLL_cnt_total++;
                        expect_result = expect_register_file[rs1] << expect_register_file[rs2][4:0]; // SLL
                    end
                    `SLT: begin
                        SLT_cnt_total++;
                        expect_result = ($signed(expect_register_file[rs1]) <
                                         $signed(expect_register_file[rs2])) ?
                            32'd1 : 32'd0;  // SLT
                    end
                    `SLTU: begin
                        SLTU_cnt_total++;
                        expect_result = ($unsigned(expect_register_file[rs1]) <
                                         $unsigned(expect_register_file[rs2])) ?
                            32'd1 : 32'd0;  // SLTU
                    end
                    `XOR: begin
                        XOR_cnt_total++;
                        expect_result = expect_register_file[rs1] ^ expect_register_file[rs2]; // XOR
                    end
                    `SRL: begin
                        SRL_cnt_total++;
                        expect_result = $unsigned(expect_register_file[rs1]) >>
                            expect_register_file[rs2][4:0];  // SRL
                    end
                    `SRA: begin
                        SRA_cnt_total++;
                        expect_result = $signed(expect_register_file[rs1]) >>>
                            expect_register_file[rs2][4:0];  // SRA
                    end
                    `OR: begin
                        OR_cnt_total++;
                        expect_result = expect_register_file[rs1] | expect_register_file[rs2]; // OR
                    end
                    `AND: begin
                        AND_cnt_total++;
                        expect_result = expect_register_file[rs1] & expect_register_file[rs2]; // AND
                    end
                    default: expect_result = 32'hxxxx_xxxx;
                endcase
                expect_register_file[rd] = expect_result;

                if (expect_register_file[rd] == tr.write_back_out_debug) begin
                    $display(
                        "[%t][%08h][PASS] rs1=x%0d rs2=x%0d rd=x%0d a=%08h b=%08h exp=%08h dut=%08h",
                        $time, gen2scb_instr_mem[tr.instr_addr_debug[31:2]],
                        rs1, rs2, rd, expect_register_file[rs1],
                        expect_register_file[rs2], expect_register_file[rd],
                        tr.write_back_out_debug);
                    R_TYPE_cnt_pass++;
                end else begin
                    $display(
                        "[%t][%08h][FAIL] rs1=x%0d rs2=x%0d rd=x%0d a=%08h b=%08h exp=%08h dut=%08h",
                        $time, gen2scb_instr_mem[tr.instr_addr_debug[31:2]],
                        rs1, rs2, rd, expect_register_file[rs1],
                        expect_register_file[rs2], expect_register_file[rd],
                        tr.write_back_out_debug);
                    R_TYPE_cnt_fail++;
                end

                expect_register_file[0] = 3'd0;
            end
            `S_TYPE: begin
                S_TYPE_cnt_total++;
                imm_i = {
                    {20{gen2scb_instr_mem[tr.instr_addr_debug[31:2]][31]}},
                    gen2scb_instr_mem[tr.instr_addr_debug[31:2]][31:25],
                    gen2scb_instr_mem[tr.instr_addr_debug[31:2]][11:7]
                };
                case (funct3)
                    `SB: begin
                        SB_cnt_total++;
                        expect_data_mem_addr = expect_register_file[rs1] + imm_i;
                        expect_data_mem_wdata = expect_register_file[rs2];
                        case (expect_data_mem_addr[1:0])
                            2'b00:
                            expect_data_memory[expect_data_mem_addr[31:2]][7:0] = expect_data_mem_wdata[7:0];
                            2'b01:
                            expect_data_memory[expect_data_mem_addr[31:2]][15:8] = expect_data_mem_wdata[7:0];
                            2'b10:
                            expect_data_memory[expect_data_mem_addr[31:2]][23:16] = expect_data_mem_wdata[7:0];
                            2'b11:
                            expect_data_memory[expect_data_mem_addr[31:2]][31:24] = expect_data_mem_wdata[7:0];
                        endcase
                    end
                    `SH: begin
                        SH_cnt_total++;
                        expect_data_mem_addr = expect_register_file[rs1] + imm_i;
                        expect_data_mem_wdata = expect_register_file[rs2];
                        case (expect_data_mem_addr[1])
                            1'b0:
                            expect_data_memory[expect_data_mem_addr[31:2]][15:0] =
                                    expect_data_mem_wdata[15:0];

                            1'b1:
                            expect_data_memory[expect_data_mem_addr[31:2]][31:16] =
                                    expect_data_mem_wdata[15:0];
                        endcase
                    end
                    `SW: begin
                        SW_cnt_total++;
                        expect_data_mem_addr = expect_register_file[rs1] + imm_i;
                        expect_data_mem_wdata = expect_register_file[rs2];
                        expect_data_memory[expect_data_mem_addr[31:2]] = expect_data_mem_wdata;
                    end
                endcase

                if ((expect_data_mem_wdata == tr.data_mem_wdata_debug) && (expect_mem_mode == tr.mem_mode_debug) 
                    && (expect_data_mem_addr == tr.data_mem_addr_debug)) begin
                    S_TYPE_cnt_pass++;
                    $display(
                        "[%t][%08h][PASS] rs1=x%0d rs2=x%0d addr=%08h wdata=%08h we=%b mode=%03b",
                        $time, gen2scb_instr_mem[tr.instr_addr_debug[31:2]],
                        rs1, rs2, expect_data_mem_addr, expect_data_mem_wdata,
                        expect_data_mem_we, expect_mem_mode);
                end else begin
                    S_TYPE_cnt_fail++;
                    $display(
                        "[%t][%08h][FAIL] rs1=x%0d rs2=x%0d exp_addr=%08h dut_addr=%08h exp_wdata=%08h dut_wdata=%08h exp_we=%b dut_we=%b exp_mode=%03b dut_mode=%03b",
                        $time, gen2scb_instr_mem[tr.instr_addr_debug[31:2]],
                        rs1, rs2, expect_data_mem_addr, tr.data_mem_addr_debug,
                        expect_data_mem_wdata, tr.data_mem_wdata_debug,
                        expect_data_mem_we, tr.data_mem_we_debug,
                        expect_mem_mode, tr.mem_mode_debug);
                end
            end
            `LOAD_I_TYPE: begin
                LOAD_I_TYPE_cnt_total++;

                imm_i = {
                    {20{gen2scb_instr_mem[tr.instr_addr_debug[31:2]][31]}},
                    gen2scb_instr_mem[tr.instr_addr_debug[31:2]][31:20]
                };

                expect_data_mem_addr = expect_register_file[rs1] + imm_i;
                expect_result = 32'd0;

                // memory 범위 밖이면 DUT처럼 0 기대
                if (expect_data_mem_addr[31:2] > 30'd63) begin
                    expect_result = 32'd0;
                end else begin
                    case (funct3)
                        `LB: begin
                            LB_cnt_total++;
                            case (expect_data_mem_addr[1:0])
                                2'b00:
                                expect_result = {
                                    {24{expect_data_memory[expect_data_mem_addr[31:2]][7]}},
                                    expect_data_memory[expect_data_mem_addr[31:2]][7:0]
                                };
                                2'b01:
                                expect_result = {
                                    {24{expect_data_memory[expect_data_mem_addr[31:2]][15]}},
                                    expect_data_memory[expect_data_mem_addr[31:2]][15:8]
                                };
                                2'b10:
                                expect_result = {
                                    {24{expect_data_memory[expect_data_mem_addr[31:2]][23]}},
                                    expect_data_memory[expect_data_mem_addr[31:2]][23:16]
                                };
                                2'b11:
                                expect_result = {
                                    {24{expect_data_memory[expect_data_mem_addr[31:2]][31]}},
                                    expect_data_memory[expect_data_mem_addr[31:2]][31:24]
                                };
                            endcase
                        end

                        `LH: begin
                            LH_cnt_total++;
                            case (expect_data_mem_addr[1])
                                1'b0:
                                expect_result = {
                                    {16{expect_data_memory[expect_data_mem_addr[31:2]][15]}},
                                    expect_data_memory[expect_data_mem_addr[31:2]][15:0]
                                };
                                1'b1:
                                expect_result = {
                                    {16{expect_data_memory[expect_data_mem_addr[31:2]][31]}},
                                    expect_data_memory[expect_data_mem_addr[31:2]][31:16]
                                };
                            endcase
                        end

                        `LW: begin
                            LW_cnt_total++;
                            expect_result = expect_data_memory[expect_data_mem_addr[31:2]];
                        end

                        `LBU: begin
                            LBU_cnt_total++;
                            case (expect_data_mem_addr[1:0])
                                2'b00:
                                expect_result = {
                                    24'd0,
                                    expect_data_memory[expect_data_mem_addr[31:2]][7:0]
                                };
                                2'b01:
                                expect_result = {
                                    24'd0,
                                    expect_data_memory[expect_data_mem_addr[31:2]][15:8]
                                };
                                2'b10:
                                expect_result = {
                                    24'd0,
                                    expect_data_memory[expect_data_mem_addr[31:2]][23:16]
                                };
                                2'b11:
                                expect_result = {
                                    24'd0,
                                    expect_data_memory[expect_data_mem_addr[31:2]][31:24]
                                };
                            endcase
                        end

                        `LHU: begin
                            LHU_cnt_total++;
                            case (expect_data_mem_addr[1])
                                1'b0:
                                expect_result = {
                                    16'd0,
                                    expect_data_memory[expect_data_mem_addr[31:2]][15:0]
                                };
                                1'b1:
                                expect_result = {
                                    16'd0,
                                    expect_data_memory[expect_data_mem_addr[31:2]][31:16]
                                };
                            endcase
                        end
                    endcase
                end

                expect_register_file[rd] = expect_result;

                if (expect_register_file[rd] == tr.write_back_out_debug) begin
                    $display(
                        "[%t][%08h][PASS] rs1=x%0d rd=x%0d addr=%08h idx=%0d off=%0d mem=%08h exp=%08h dut=%08h",
                        $time, gen2scb_instr_mem[tr.instr_addr_debug[31:2]],
                        rs1, rd, expect_data_mem_addr,
                        expect_data_mem_addr[31:2], expect_data_mem_addr[1:0],
                        expect_data_memory[expect_data_mem_addr[31:2]],
                        expect_result, tr.write_back_out_debug);

                    LOAD_I_TYPE_cnt_pass++;
                end else begin
                    LOAD_I_TYPE_cnt_fail++;

                    $display(
                        "[%t][%08h][FAIL] rs1=x%0d rd=x%0d exp_addr=%08h dut_addr=%08h idx=%0d off=%0d mem=%08h exp=%08h dut=%08h",
                        $time, gen2scb_instr_mem[tr.instr_addr_debug[31:2]],
                        rs1, rd, expect_data_mem_addr, tr.data_mem_addr_debug,
                        expect_data_mem_addr[31:2], expect_data_mem_addr[1:0],
                        expect_data_memory[expect_data_mem_addr[31:2]],
                        expect_result, tr.write_back_out_debug);
                end

                expect_register_file[0] = 3'd0;
            end
            `ALU_I_TYPE: begin
                ALU_I_TYPE_cnt_total++;
                imm_i = {
                    {20{gen2scb_instr_mem[tr.instr_addr_debug[31:2]][31]}},
                    gen2scb_instr_mem[tr.instr_addr_debug[31:2]][31:20]
                };
                case (funct3)
                    `ADDI: begin
                        ADDI_cnt_total++;
                        expect_result = expect_register_file[rs1] + imm_i;  // ADDI
                    end
                    `SLTI: begin
                        SLTI_cnt_total++;
                        expect_result = ($signed(expect_register_file[rs1]) <
                                         $signed(imm_i)) ? 32'd1 :
                            32'd0;  // SLTI
                    end
                    `SLTIU: begin
                        SLTIU_cnt_total++;
                        expect_result = (expect_register_file[rs1] < imm_i) ? 32'd1 : 32'd0; // SLTIU
                    end
                    `XORI: begin
                        XORI_cnt_total++;
                        expect_result = expect_register_file[rs1] ^ imm_i;  // XORI
                    end
                    `ORI: begin
                        ORI_cnt_total++;
                        expect_result = expect_register_file[rs1] | imm_i;  // ORI
                    end
                    `ANDI: begin
                        ANDI_cnt_total++;
                        expect_result = expect_register_file[rs1] & imm_i;  // ANDI
                    end

                    3'b001: begin
                        // SLLI
                        SLLI_cnt_total++;
                        expect_result = expect_register_file[rs1] << imm_i[4:0];
                    end
                    3'b101: begin
                        if (funct7[5] == 1'b0) begin
                            SRLI_cnt_total++;
                            // SRLI
                            expect_result = $unsigned(
                                expect_register_file[rs1]) >> imm_i[4:0];
                        end else begin
                            SRAI_cnt_total++;
                            // SRAI
                            expect_result = $signed(
                                expect_register_file[rs1]) >>> imm_i[4:0];
                        end
                    end

                    default: expect_result = 32'hxxxx_xxxx;
                endcase

                expect_register_file[rd] = expect_result;

                if (expect_register_file[rd] == tr.write_back_out_debug) begin
                    $display(
                        "[%t][%08h][PASS] rs1=x%0d rd=x%0d a=%08h imm=%08h exp=%08h dut=%08h",
                        $time, gen2scb_instr_mem[tr.instr_addr_debug[31:2]],
                        rs1, rd, expect_register_file[rs1], imm_i,
                        expect_register_file[rd], tr.write_back_out_debug);
                    ALU_I_TYPE_cnt_pass++;
                end else begin
                    $display(
                        "[%t][%08h][FAIL] rs1=x%0d rd=x%0d a=%08h imm=%08h exp=%08h dut=%08h",
                        $time, gen2scb_instr_mem[tr.instr_addr_debug[31:2]],
                        rs1, rd, expect_register_file[rs1], imm_i,
                        expect_register_file[rd], tr.write_back_out_debug);
                    ALU_I_TYPE_cnt_fail++;
                end

                expect_register_file[0] = 3'd0;
            end
            // ===============================================
            `B_TYPE: begin
                B_TYPE_cnt_total++;

                imm_b = {
                    {19{gen2scb_instr_mem[tr.instr_addr_debug[31:2]][31]}},
                    gen2scb_instr_mem[tr.instr_addr_debug[31:2]][31],
                    gen2scb_instr_mem[tr.instr_addr_debug[31:2]][7],
                    gen2scb_instr_mem[tr.instr_addr_debug[31:2]][30:25],
                    gen2scb_instr_mem[tr.instr_addr_debug[31:2]][11:8],
                    1'b0
                };

                case (funct3)
                    `BEQ: begin
                        BEQ_cnt_total++;
                        expect_b_taken = (expect_register_file[rs1] == expect_register_file[rs2]);
                    end
                    `BNE: begin
                        BNE_cnt_total++;
                        expect_b_taken = (expect_register_file[rs1] != expect_register_file[rs2]);
                    end
                    `BLT: begin
                        BLT_cnt_total++;
                        expect_b_taken = ($signed(expect_register_file[rs1]) <
                                          $signed(expect_register_file[rs2]));
                    end
                    `BGE: begin
                        BGE_cnt_total++;
                        expect_b_taken = ($signed(expect_register_file[rs1]) >=
                                          $signed(expect_register_file[rs2]));
                    end
                    `BLTU: begin
                        BLTU_cnt_total++;
                        expect_b_taken = ($unsigned(expect_register_file[rs1]) <
                                          $unsigned(expect_register_file[rs2]));
                    end
                    `BGEU: begin
                        BGEU_cnt_total++;
                        expect_b_taken = (
                            $unsigned(expect_register_file[rs1]) >=
                                $unsigned(expect_register_file[rs2]));
                    end
                    default: expect_b_taken = 1'b0;
                endcase

                if (expect_b_taken == tr.b_taken_debug) begin
                    B_TYPE_cnt_pass++;
                    $display(
                        "[%t][%08h][PASS] rs1=x%0d rs2=x%0d a=%08h b=%08h exp_taken=%b dut_taken=%b",
                        $time, gen2scb_instr_mem[tr.instr_addr_debug[31:2]],
                        rs1, rs2, expect_register_file[rs1],
                        expect_register_file[rs2], expect_b_taken,
                        tr.b_taken_debug);
                end else begin
                    B_TYPE_cnt_fail++;
                    $display(
                        "[%t][%08h][FAIL] rs1=x%0d rs2=x%0d a=%08h b=%08h exp_taken=%b dut_taken=%b",
                        $time, gen2scb_instr_mem[tr.instr_addr_debug[31:2]],
                        rs1, rs2, expect_register_file[rs1],
                        expect_register_file[rs2], expect_b_taken,
                        tr.b_taken_debug);
                end
            end

            `LUI_TYPE: begin
                LUI_TYPE_cnt_total++;

                imm_u = {
                    gen2scb_instr_mem[tr.instr_addr_debug[31:2]][31:12], 12'b0
                };
                expect_result = imm_u;

                if (expect_result == tr.write_back_out_debug) begin
                    LUI_TYPE_cnt_pass++;
                    $display(
                        "[%t][%08h][PASS] rd=x%0d imm=%08h exp=%08h dut=%08h",
                        $time, gen2scb_instr_mem[tr.instr_addr_debug[31:2]],
                        rd, imm_u, expect_result, tr.write_back_out_debug);
                end else begin
                    LUI_TYPE_cnt_fail++;
                    $display(
                        "[%t][%08h][FAIL] rd=x%0d imm=%08h exp=%08h dut=%08h",
                        $time, gen2scb_instr_mem[tr.instr_addr_debug[31:2]],
                        rd, imm_u, expect_result, tr.write_back_out_debug);
                end

                expect_register_file[rd] = expect_result;

                expect_register_file[0] = 32'd0;
            end

            `AUIPC_TYPE: begin
                AUIPC_TYPE_cnt_total++;

                imm_u = {
                    gen2scb_instr_mem[tr.instr_addr_debug[31:2]][31:12], 12'b0
                };
                expect_result = tr.instr_addr_debug + imm_u;

                if (expect_result == tr.write_back_out_debug) begin
                    AUIPC_TYPE_cnt_pass++;
                    $display(
                        "[%t][%08h][PASS] rd=x%0d pc=%08h imm=%08h exp=%08h dut=%08h",
                        $time, gen2scb_instr_mem[tr.instr_addr_debug[31:2]],
                        rd, tr.instr_addr_debug, imm_u, expect_result,
                        tr.write_back_out_debug);
                end else begin
                    AUIPC_TYPE_cnt_fail++;
                    $display(
                        "[%t][%08h][FAIL] rd=x%0d pc=%08h imm=%08h exp=%08h dut=%08h",
                        $time, gen2scb_instr_mem[tr.instr_addr_debug[31:2]],
                        rd, tr.instr_addr_debug, imm_u, expect_result,
                        tr.write_back_out_debug);
                end

                expect_register_file[rd] = expect_result;

                expect_register_file[0] = 32'd0;
            end
`JAL_TYPE: begin
    JAL_TYPE_cnt_total++;

    imm_j = {
        {11{gen2scb_instr_mem[tr.instr_addr_debug[31:2]][31]}},
        gen2scb_instr_mem[tr.instr_addr_debug[31:2]][31],
        gen2scb_instr_mem[tr.instr_addr_debug[31:2]][19:12],
        gen2scb_instr_mem[tr.instr_addr_debug[31:2]][20],
        gen2scb_instr_mem[tr.instr_addr_debug[31:2]][30:21],
        1'b0
    };

    expect_pc_next = tr.instr_addr_debug + imm_j;
    expect_result  = tr.instr_addr_debug + 32'd4;  // rd = PC + 4

    if ((expect_pc_next == tr.instr_addr_debug) &&
        (expect_result  == tr.write_back_out_debug)) begin

        JAL_TYPE_cnt_pass++;
        $display(
            "[%t][%08h][PASS][JAL] rd=x%0d pc=%08h imm=%08h exp_pc_next=%08h dut_pc_next=%08h exp_link=%08h dut_link=%08h",
            $time,
            gen2scb_instr_mem[tr.instr_addr_debug[31:2]],
            rd,
            tr.instr_addr_debug,
            imm_j,
            expect_pc_next,
            tr.instr_addr_debug,
            expect_result,
            tr.write_back_out_debug
        );

    end else begin
        JAL_TYPE_cnt_fail++;
        $display(
            "[%t][%08h][FAIL][JAL] rd=x%0d pc=%08h imm=%08h exp_pc_next=%08h dut_pc_next=%08h exp_link=%08h dut_link=%08h",
            $time,
            gen2scb_instr_mem[tr.instr_addr_debug[31:2]],
            rd,
            tr.instr_addr_debug,
            imm_j,
            expect_pc_next,
            tr.instr_addr_debug,
            expect_result,
            tr.write_back_out_debug
        );
    end

    expect_register_file[rd] = expect_result;
    expect_register_file[0]  = 32'd0;
end

            `JALR_TYPE: begin
                JALR_TYPE_cnt_total++;

                imm_i = {
                    {20{gen2scb_instr_mem[tr.instr_addr_debug[31:2]][31]}},
                    gen2scb_instr_mem[tr.instr_addr_debug[31:2]][31:20]
                };

                expect_result = tr.instr_addr_debug + 32'd4;

                if (expect_result == tr.write_back_out_debug) begin
                    JALR_TYPE_cnt_pass++;
                    $display(
                        "[%t][%08h][PASS] rs1=x%0d rd=x%0d pc=%08h imm=%08h exp_link=%08h dut=%08h",
                        $time, gen2scb_instr_mem[tr.instr_addr_debug[31:2]],
                        rs1, rd, tr.instr_addr_debug, imm_i, expect_result,
                        tr.write_back_out_debug);
                end else begin
                    JALR_TYPE_cnt_fail++;
                    $display(
                        "[%t][%08h][FAIL] rs1=x%0d rd=x%0d pc=%08h imm=%08h exp_link=%08h dut=%08h",
                        $time, gen2scb_instr_mem[tr.instr_addr_debug[31:2]],
                        rs1, rd, tr.instr_addr_debug, imm_i, expect_result,
                        tr.write_back_out_debug);
                end

                expect_register_file[rd] = expect_result;

                expect_register_file[0] = 32'd0;
            end
            // ===============================================
        endcase

    endtask

    task run();
        forever begin
            mon2drv_mbox.get(tr);
            compare(tr);
        end
    endtask
endclass

class environment;
    generator gen;
    monitor mon;
    scoreboard scb;

    mailbox #(transaction) mon2drv_mbox;

    logic [31:0] gen2scb_instr_mem[0:(`INSTR_MEM_WORDS)-1];

    function new(virtual rv32i_interface _v_rv32i_if);
        mon2drv_mbox = new();
        gen = new();
        mon = new(_v_rv32i_if, mon2drv_mbox);
    endfunction

    task run();
        gen.run(gen2scb_instr_mem);
        scb = new(gen2scb_instr_mem, mon2drv_mbox);

        fork
            mon.run((`INSTR_MEM_WORDS));
            scb.run();
        join_any

        $display(
            "===================== END Randomize Test =====================");
        $display("===================== OPCODE Compare =====================");
        $display(
            "OPCODE total cnt = %d, OPCODE pass cnt = %d, OPCODE fail cnt = %d",
            scb.OPCODE_cnt_total, scb.OPCODE_cnt_pass, scb.OPCODE_cnt_fail);

        $display("===================== R-TYPE Compare =====================");
        $display(
            "R-TYPE total cnt = %d, R-TYPE pass cnt = %d, R-TYPE fail cnt = %d",
            scb.R_TYPE_cnt_total, scb.R_TYPE_cnt_pass, scb.R_TYPE_cnt_fail);

        $display("ADD cnt = %0d", scb.ADD_cnt_total);
        $display("SUB cnt = %0d", scb.SUB_cnt_total);
        $display("SLL cnt = %0d", scb.SLL_cnt_total);
        $display("SLT cnt = %0d", scb.SLT_cnt_total);
        $display("SLTU cnt = %0d", scb.SLTU_cnt_total);
        $display("XOR cnt = %0d", scb.XOR_cnt_total);
        $display("SRL cnt = %0d", scb.SRL_cnt_total);
        $display("SRA cnt = %0d", scb.SRA_cnt_total);
        $display("OR cnt = %0d", scb.OR_cnt_total);
        $display("AND cnt = %0d", scb.AND_cnt_total);

        $display(
            "===================== ALU-I-TYPE Compare =====================");
        $display(
            "ALU-I-TYPE total cnt = %d, ALU-I-TYPE pass cnt = %d, ALU-I-TYPE fail cnt = %d",
            scb.ALU_I_TYPE_cnt_total, scb.ALU_I_TYPE_cnt_pass,
            scb.ALU_I_TYPE_cnt_fail);

        $display("ADDI cnt = %0d", scb.ADDI_cnt_total);
        $display("SLTI cnt = %0d", scb.SLTI_cnt_total);
        $display("SLTIU cnt = %0d", scb.SLTIU_cnt_total);
        $display("XORI cnt = %0d", scb.XORI_cnt_total);
        $display("ORI cnt = %0d", scb.ORI_cnt_total);
        $display("ANDI cnt = %0d", scb.ANDI_cnt_total);
        $display("SLLI cnt = %0d", scb.SLLI_cnt_total);
        $display("SRLI cnt = %0d", scb.SRLI_cnt_total);
        $display("SRAI cnt = %0d", scb.SRAI_cnt_total);

        $display("===================== S-TYPE Compare =====================");
        $display(
            "S-TYPE total cnt = %d, S-TYPE pass cnt = %d, S-TYPE fail cnt = %d",
            scb.S_TYPE_cnt_total, scb.S_TYPE_cnt_pass, scb.S_TYPE_cnt_fail);

        $display("SB cnt = %0d", scb.SB_cnt_total);
        $display("SH cnt = %0d", scb.SH_cnt_total);
        $display("SW cnt = %0d", scb.SW_cnt_total);

        $display(
            "===================== LOAD-I-TYPE Compare =====================");
        $display(
            "LOAD-I-TYPE total cnt = %d, LOAD-I-TYPE pass cnt = %d, LOAD-I-TYPE fail cnt = %d",
            scb.LOAD_I_TYPE_cnt_total, scb.LOAD_I_TYPE_cnt_pass,
            scb.LOAD_I_TYPE_cnt_fail);

        $display("LB cnt = %0d", scb.LB_cnt_total);
        $display("LH cnt = %0d", scb.LH_cnt_total);
        $display("LW cnt = %0d", scb.LW_cnt_total);
        $display("LBU cnt = %0d", scb.LBU_cnt_total);
        $display("LHU cnt = %0d", scb.LHU_cnt_total);

        $display("===================== B-TYPE Compare =====================");
        $display(
            "B-TYPE total cnt = %d, B-TYPE pass cnt = %d, B-TYPE fail cnt = %d",
            scb.B_TYPE_cnt_total, scb.B_TYPE_cnt_pass, scb.B_TYPE_cnt_fail);

        $display("BEQ cnt = %0d", scb.BEQ_cnt_total);
        $display("BNE cnt = %0d", scb.BNE_cnt_total);
        $display("BLT cnt = %0d", scb.BLT_cnt_total);
        $display("BGE cnt = %0d", scb.BGE_cnt_total);
        $display("BLTU cnt = %0d", scb.BLTU_cnt_total);
        $display("BGEU cnt = %0d", scb.BGEU_cnt_total);


        $display(
            "===================== LUI-TYPE Compare =====================");
        $display(
            "LUI-TYPE total cnt = %d, LUI-TYPE pass cnt = %d, LUI-TYPE fail cnt = %d",
            scb.LUI_TYPE_cnt_total, scb.LUI_TYPE_cnt_pass,
            scb.LUI_TYPE_cnt_fail);

        $display(
            "===================== AUIPC-TYPE Compare =====================");
        $display(
            "AUIPC-TYPE total cnt = %d, AUIPC-TYPE pass cnt = %d, AUIPC-TYPE fail cnt = %d",
            scb.AUIPC_TYPE_cnt_total, scb.AUIPC_TYPE_cnt_pass,
            scb.AUIPC_TYPE_cnt_fail);

        $display(
            "===================== JAL-TYPE Compare =====================");
        $display(
            "JAL-TYPE total cnt = %d, JAL-TYPE pass cnt = %d, JAL-TYPE fail cnt = %d",
            scb.JAL_TYPE_cnt_total, scb.JAL_TYPE_cnt_pass,
            scb.JAL_TYPE_cnt_fail);

        $display(
            "===================== JALR-TYPE Compare =====================");
        $display(
            "JALR-TYPE total cnt = %d, JALR-TYPE pass cnt = %d, JALR-TYPE fail cnt = %d",
            scb.JALR_TYPE_cnt_total, scb.JALR_TYPE_cnt_pass,
            scb.JALR_TYPE_cnt_fail);

        scb.TOTAL_cnt_total =
        scb.R_TYPE_cnt_total
        + scb.ALU_I_TYPE_cnt_total
        + scb.S_TYPE_cnt_total
        + scb.LOAD_I_TYPE_cnt_total
        + scb.B_TYPE_cnt_total
        + scb.LUI_TYPE_cnt_total
        + scb.AUIPC_TYPE_cnt_total
        + scb.JAL_TYPE_cnt_total
        + scb.JALR_TYPE_cnt_total;

        scb.TOTAL_cnt_pass =
        scb.R_TYPE_cnt_pass
        + scb.ALU_I_TYPE_cnt_pass
        + scb.S_TYPE_cnt_pass
        + scb.LOAD_I_TYPE_cnt_pass
        + scb.B_TYPE_cnt_pass
        + scb.LUI_TYPE_cnt_pass
        + scb.AUIPC_TYPE_cnt_pass
        + scb.JAL_TYPE_cnt_pass
        + scb.JALR_TYPE_cnt_pass;

        scb.TOTAL_cnt_fail =
        scb.R_TYPE_cnt_fail
        + scb.ALU_I_TYPE_cnt_fail
        + scb.S_TYPE_cnt_fail
        + scb.LOAD_I_TYPE_cnt_fail
        + scb.B_TYPE_cnt_fail
        + scb.LUI_TYPE_cnt_fail
        + scb.AUIPC_TYPE_cnt_fail
        + scb.JAL_TYPE_cnt_fail
        + scb.JALR_TYPE_cnt_fail;

        $display("===================== TOTAL RESULT =====================");
        $display("TOTAL cnt = %0d, PASS cnt = %0d, FAIL cnt = %0d",
                 scb.TOTAL_cnt_total, scb.TOTAL_cnt_pass, scb.TOTAL_cnt_fail);
        $finish();
    endtask
endclass

module tb_rv32i_uvm ();
    rv32i_interface rv32i_if ();
    environment env;

    

    top_rv32i_soc_debug dut (
        .clk  (rv32i_if.clk),
        .rst_n(rv32i_if.rst_n),

        // data memory
        .mem_mode_debug      (rv32i_if.mem_mode_debug),
        .data_mem_we_debug   (rv32i_if.data_mem_we_debug),
        .data_mem_wdata_debug(rv32i_if.data_mem_wdata_debug),
        .data_mem_addr_debug (rv32i_if.data_mem_addr_debug),
        .data_mem_rdata_debug(rv32i_if.data_mem_rdata_debug),

        .b_taken_debug       (rv32i_if.b_taken_debug),
        .instr_addr_debug    (rv32i_if.instr_addr_debug),
        .write_back_out_debug(rv32i_if.write_back_out_debug),
        .rs1_debug           (rv32i_if.rs1_debug),
        .reg_we_debug        (rv32i_if.reg_we_debug),
        .instr_code_debug    (rv32i_if.instr_code_debug)
    );

    always #5 rv32i_if.clk = ~rv32i_if.clk;

    initial begin
        rv32i_if.clk   = 0;
        rv32i_if.rst_n = 0;
        #10;
        rv32i_if.rst_n = 1;
    end

    initial begin
        env = new(rv32i_if);
        env.run();
        
    end
endmodule
