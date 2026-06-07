// OP-CODE intruction
`define R_TYPE 7'b011_0011 
`define S_TYPE 7'b010_0011
`define LOAD_I_TYPE 7'b000_0011
`define ALU_I_TYPE 7'b001_0011
`define B_TYPE 7'b110_0011
`define LUI_TYPE 7'b011_0111
`define AUIPC_TYPE 7'b001_0111
`define JAL_TYPE 7'b110_1111
`define JALR_TYPE 7'b110_0111

// R-type instruction
// {funct7, funct3} = 10bit
/*
`define ADD  10'b000_0000_000
`define SUB  10'b010_0000_000
`define SLL  10'b000_0000_001
`define SLT  10'b000_0000_010
`define SLTU 10'b000_0000_011
`define XOR  10'b000_0000_100
`define SRL  10'b000_0000_101
`define SRA  10'b010_0000_101
`define OR   10'b000_0000_110
`define AND  10'b000_0000_111
*/

// Register-type instruction
// {funct7, funct3} = 4bit
`define ADD  4'b0_000
`define SUB  4'b1_000
`define SLL  4'b0_001
`define SLT  4'b0_010
`define SLTU 4'b0_011
`define XOR  4'b0_100
`define SRL  4'b0_101
`define SRA  4'b1_101
`define OR   4'b0_110
`define AND  4'b0_111

// Immediate ALU 연산 계열
`define ADDI 3'b000
`define SLTI 3'b010
`define SLTIU 3'b011
`define XORI 3'b100
`define ORI 3'b110
`define ANDI 3'b111
`define SLLI 4'b0_001
`define SRLI 4'b0_101
`define SRAI 4'b1_101

// Store-type instruction
`define SB 3'b000
`define SH 3'b001
`define SW 3'b010

// Load-type instruction
`define LB 3'b000
`define LH 3'b001
`define LW 3'b010
`define LBU 3'b100
`define LHU 3'b101

// Branch B-type instruction
`define BEQ 3'b000
`define BNE 3'b001
`define BLT 3'b100
`define BGE 3'b101
`define BLTU 3'b110
`define BGEU 3'b111
