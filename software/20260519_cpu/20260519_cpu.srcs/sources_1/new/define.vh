// OP-CODE intruction
`define R_TYPE 7'b011_0011 
`define I_TYPE 7'b000_0011
`define U_TYPE 7'b011_0111
`define S_TYPE 7'b010_0011
`define B_TYPE 7'b110_0011
`define J_TYPE 7'b110_0111

// R-type instruction
// {funct7, funct3} = 10bit
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