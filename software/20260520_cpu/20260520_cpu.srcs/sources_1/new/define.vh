// opcode
`define R_TYPE 7'b011_0011
`define B_TYPE 7'110_0011
`define S_TYPE 7'b010_0011
`define J_TYPE 7'110_0111
`define LOAD_I_TYPE 7'b000_0011
`define ALU_I_TYPE 7'b001_0011
`define FENCE_I_TYPE 7'b000_1111
`define ECALL_I_TYPE 7'b111_0011
`define LUI_U_TYPE 


// {funct7, funct3}
`define ADD 10'b000_0000_000
`define SUB 10'b010_0000_000
`define SLL 10'b000_0000_001
`define SLT 10'b000_0000_010
`define SLTU 10'b000_0000_011
`define XOR 10'b000_0000_100
`define SRL 10'b000_0000_101
`define SRA 10'b010_0000_101
`define OR 10'b000_0000_110
`define AND 10'b000_0000_111


// ALU 연산 계열
`define ADDI 3'b000
`define SLTI 3'b010
`define SLTIU 3'b011
`define XORI 3'b100
`define ORI 3'b110
`define ANDI 3'b111
`define SLLI 10'b000_0000_001
`define SRLI 10'b000_0000_101
`define SRAI 10'b010_0000_101

// 메모리 접근 계열
`define LB 3'b000
`define LH 3'b001
`define LW 3'b010
`define LBU 3'b100
`define LHU 3'b101