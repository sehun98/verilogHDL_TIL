`timescale 1ns / 1ps
`include "define.vh"

module rv32i_control_unit (
    input  wire [6:0] funct7,
    input  wire [2:0] funct3,
    input  wire [6:0] opcode,
    output reg       register_file_we,
    output reg [9:0] alu_control
);

// state 관리가 필요없음.
always_comb begin
    register_file_we = 1'b0;
    alu_control = 32'd0;
    case(opcode)
        `R_TYPE : begin
            register_file_we = 1'b1;
            case({funct7,funct3})
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
        end
//        `S_TYPE : begin
//            case({funct7,funct3})
//
//            endcase
//        end
    endcase
end
endmodule
