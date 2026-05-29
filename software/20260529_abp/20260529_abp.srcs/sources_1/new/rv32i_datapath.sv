`timescale 1ns / 1ps
`include "define.vh"
// 명령어, 블록도
module rv32i_datapath (
    input  wire        clk,
    input  wire        rst_n,

    input  wire [31:0] instr_code,
    output wire [31:0] instr_addr,

    input wire [3:0] alu_control,     // 10bit -> 4bit
    input wire       alu_src_sel,
    input wire [2:0] write_back_sel,
    input wire       reg_we,

    output wire [31:0] WDATA,
    output wire [31:0] ADDR,
    input  wire [31:0] RDATA,

    input wire dec_rs1_en,
    input wire dec_rs1_bubble,
    input wire dec_rs2_en,
    input wire dec_rs2_bubble,
    input wire exe_alu_en,
    input wire exe_alu_bubble,
    input wire exe_rs2_en,
    input wire exe_rs2_bubble,
    input wire dec_imm_en,
    input wire dec_imm_bubble,
    input wire mem_rdata_en,
    input wire mem_rdata_bubble,
    
    input wire exe_pc_next_en,
    input wire exe_pc_next_bubble,

    input wire pc_en,
    input wire pc_branch,
    input wire pc_jal,
    input wire pc_jalr
);
    wire [31:0] w_rs1;
    wire [31:0] w_rs1_decode;

    wire [31:0] w_rs2;
    wire [31:0] w_rs2_decode;

    wire [31:0] w_alu_out;
    wire [31:0] w_alu_exe;

    wire [31:0] w_rs2_exe;
    
    wire [31:0] w_alu_b_src;

    wire [31:0] w_dec_imm;

    wire [31:0] w_mem_rdata;

    wire [31:0] w_immediate_code;

    wire w_b_taken;

    wire [31:0] w_pc_imm;
    wire [31:0] w_pc_4;
    wire [31:0] w_write_back_out;

    rv32i_register_file u1_rv32i_register_file (
        .clk(clk),
        // control unit
        .raddr1(instr_code[19:15]),
        .raddr2(instr_code[24:20]),
        .waddr(instr_code[11:7]),
        .reg_we(reg_we),

        // alu
        .wdata (w_write_back_out),
        .rdata1(w_rs1),
        .rdata2(w_rs2)
    );

    rv32i_alu u2_rv32i_alu (
        .rs1        (w_rs1_decode),
        .rs2        (w_alu_b_src),
        .alu_control(alu_control),
        .alu_out    (w_alu_out),
        .b_taken    (w_b_taken)
    );

    pipeline_register dec_rs1 (
        .clk(clk),
        .rst_n(rst_n),
        .din(w_rs1),
        .dout(w_rs1_decode),
        .en(dec_rs1_en),
        .bubble(dec_rs1_bubble)
    );

    pipeline_register dec_rs2 (
        .clk(clk),
        .rst_n(rst_n),
        .din(w_rs2),
        .dout(w_rs2_decode),
        .en(dec_rs2_en),
        .bubble(dec_rs2_bubble)
    );

    pipeline_register exe_alu (
        .clk(clk),
        .rst_n(rst_n),
        .din(w_alu_out),
        .dout(w_alu_exe),
        .en(exe_alu_en),
        .bubble(exe_alu_bubble)
    );

    pipeline_register exe_rs2 (
        .clk(clk),
        .rst_n(rst_n),
        .din(w_rs2_decode),
        .dout(w_rs2_exe),
        .en(exe_rs2_en),
        .bubble(exe_rs2_bubble)
    );

    assign data_mem_addr  = w_alu_exe;
    assign data_mem_wdata = w_rs2_exe;

    immediate_generator u3_immediate_generator (
        .instr_code    (instr_code),
        .immediate_code(w_immediate_code)
    );

    pipeline_register dec_imm (
        .clk(clk),
        .rst_n(rst_n),
        .din(w_immediate_code),
        .dout(w_dec_imm),
        .en(dec_imm_en),
        .bubble(dec_imm_bubble)
    );

    assign w_alu_b_src = alu_src_sel ? w_dec_imm : w_rs2_decode;

    rv32i_program_counter u5_rv32i_program_counter (
        .clk  (clk),
        .rst_n(rst_n),

        .immediate_code(w_dec_imm),
        .rs1           (w_rs1_decode),
        .b_taken       (w_b_taken),

        // control unit
        .pc_branch         (pc_branch),
        .pc_jal            (pc_jal),
        .pc_jalr           (pc_jalr),
        .pc_en             (pc_en),
        .exe_pc_next_en    (exe_pc_next_en),
        .exe_pc_next_bubble(exe_pc_next_bubble),

        // write_back
        .pc_imm(w_pc_imm),
        .pc_4  (w_pc_4),

        // instruction memory
        .pc_out(instr_addr)
    );

    write_back u6_write_back (
        .in0(w_alu_out),
        .in1(w_mem_rdata),
        .in2(w_dec_imm),
        .in3(w_pc_imm),
        .in4(w_pc_4),

        .write_back_sel(write_back_sel),
        .write_back_out(w_write_back_out)
    );

    pipeline_register mem_rdata (
        .clk(clk),
        .rst_n(rst_n),
        .din(data_mem_rdata),
        .dout(w_mem_rdata),
        .en(mem_rdata_en),
        .bubble(mem_rdata_bubble)
    );
endmodule

module rv32i_register_file (
    input wire clk,
    // instruction memory
    input wire [4:0] raddr1,  // mem size 32
    input wire [4:0] raddr2,
    input wire [4:0] waddr,
    // control unit
    input wire reg_we,
    // feedback
    input wire [31:0] wdata,
    // alu
    output wire [31:0] rdata1,
    output wire [31:0] rdata2
);
    reg [31:0] mem[1:31];
    `ifdef TEST_SIMULATION
        initial begin
            for (int i = 0; i < 32; i = i + 1) begin
                mem[i] = 0;
            end
        end
    `endif
    always_ff @(posedge clk) begin
        if (reg_we) begin
            mem[waddr] <= wdata;
        end
    end
    assign rdata1 = (raddr1 == 5'd0) ? 32'd0 : mem[raddr1];
    assign rdata2 = (raddr2 == 5'd0) ? 32'd0 : mem[raddr2];
endmodule

module rv32i_alu (
    input wire [31:0] rs1,
    input wire [31:0] rs2,
    input wire [3:0] alu_control,  // {funct7, func3} 10bit -> {funct7[5], func3} 4bit
    output wire [31:0] alu_out,
    output wire b_taken
);
    reg [31:0] alu_out_reg;
    reg b_taken_reg;
    assign alu_out = alu_out_reg;
    assign b_taken = b_taken_reg;
    always_comb begin
        alu_out_reg = 32'd0;
        case (alu_control)
            // R-type : Rd = Rs1 + Rs2
            // I-ALU-type : Rd = Rs1 + Imm
            `ADD: alu_out_reg = rs1 + rs2;
            `SUB: alu_out_reg = rs1 - rs2;
            `SLL: alu_out_reg = rs1 << rs2[4:0];  // 2^5 =32 a<<b; 
            `SLT: alu_out_reg = ($signed(rs1) < $signed(rs2)) ? 32'd1 : 32'd0;
            `SLTU:
            alu_out_reg = ($unsigned(rs1) < $unsigned(rs2)) ? 32'd1 :
                32'd0;  // zero-extention
            `XOR: alu_out_reg = rs1 ^ rs2;
            `SRL: alu_out_reg = rs1 >> rs2[4:0];  // a>>b;
            `SRA:
            alu_out_reg = $signed(rs1) >>> rs2[4:0];  // a>>b; // msb-extention
            `OR: alu_out_reg = rs1 | rs2;
            `AND: alu_out_reg = rs1 & rs2;
            //`MUL: alu_out_reg = rs1 * rs2;
        endcase
    end

    always_comb begin
        b_taken_reg = 1'd0;
        case (alu_control[2:0])  // 0000 -> 000
            // branch-type : PC += imm
            `BEQ: begin
                if (rs1 == rs2) begin
                    b_taken_reg = 1'b1;
                end else begin
                    b_taken_reg = 1'b0;
                end
            end
            `BNE: begin
                if (rs1 != rs2) begin
                    b_taken_reg = 1'b1;
                end else begin
                    b_taken_reg = 1'b0;
                end
            end
            `BLT: begin
                if ($signed(rs1) < $signed(rs2)) begin
                    b_taken_reg = 1'b1;
                end else begin
                    b_taken_reg = 1'b0;
                end
            end
            `BGE: begin
                if ($signed(rs1) >= $signed(rs2)) begin
                    b_taken_reg = 1'b1;
                end else begin
                    b_taken_reg = 1'b0;
                end
            end
            `BLTU: begin
                if ($unsigned(rs1) < $unsigned(rs2)) begin
                    b_taken_reg = 1'b1;
                end else begin
                    b_taken_reg = 1'b0;
                end
            end
            `BGEU: begin
                if ($unsigned(rs1) >= $unsigned(rs2)) begin
                    b_taken_reg = 1'b1;
                end else begin
                    b_taken_reg = 1'b0;
                end
            end
        endcase
    end
endmodule

module rv32i_program_counter (
    input wire clk,
    input wire rst_n,
    input wire [31:0] immediate_code,
    input wire [31:0] rs1,
    input wire b_taken,
    input wire pc_branch,
    input wire pc_jal,
    input wire pc_jalr,

    input wire pc_en,
    input wire exe_pc_next_en,
    input wire exe_pc_next_bubble,

    output wire [31:0] pc_imm,
    output wire [31:0] pc_4,
    output wire [31:0] pc_out
);
    reg [31:0] pc_reg;
    reg [31:0] pc_next_exe;
    reg [31:0] pc_next;
    reg [31:0] pc_base_out;

    assign pc_out = pc_reg;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc_reg <= 32'd0;
        end else begin
            if (pc_en) begin
                pc_reg <= pc_next_exe;
            end
        end
    end
    assign pc_imm = immediate_code + pc_base_out;
    assign pc_4 = pc_reg + 32'd4;
    assign pc_next = (pc_jalr | pc_jal | (pc_branch & b_taken)) ? (pc_imm) : (pc_4);
    assign pc_base_out = pc_jalr ? rs1 : pc_reg;  // pc_base_mux

    pipeline_register exe_pc_next (
        .clk(clk),
        .rst_n(rst_n),
        .din(pc_next),
        .dout(pc_next_exe),
        .en(exe_pc_next_en),
        .bubble(exe_pc_next_bubble)
    );
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
            `LUI_TYPE, `AUIPC_TYPE:
            immediate_code_reg = {instr_code[31:12], {12{1'b0}}};
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

module write_back (
    input  wire [31:0] in0,
    input  wire [31:0] in1,
    input  wire [31:0] in2,
    input  wire [31:0] in3,
    input  wire [31:0] in4,
    input  wire [ 2:0] write_back_sel,
    output wire [31:0] write_back_out
);
    reg [31:0] write_back_out_reg;

    always_comb begin
        case (write_back_sel)
            3'd0: write_back_out_reg = in0;  // load  alu
            3'd1: write_back_out_reg = in1;  // load data memory
            3'd2: write_back_out_reg = in2;  // load LUI : load upper imm
            3'd3: write_back_out_reg = in3;  // load Add upper Imm to PC
            3'd4: write_back_out_reg = in4;  // load JAL, JARL : PC + 4
            default: write_back_out_reg = in0;
        endcase
    end
    assign write_back_out = write_back_out_reg;
endmodule

module pipeline_register (
    input wire clk,
    input wire rst_n,
    input wire [31:0] din,
    output wire [31:0] dout,
    input wire en,
    input wire bubble
);

    reg [31:0] dout_reg;

    assign dout = dout_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dout_reg <= 32'd0;
        end else begin
            dout_reg <= din;
            
            if (bubble) begin
                dout_reg <= 32'd0;
            end else if (en) begin
                //dout_reg <= din;
            end
        end
    end
endmodule
