`timescale 1ns / 1ps
`include "define.vh"

module instruction_memory_debug (
    input  wire [31:0] instr_addr,
    output wire [31:0] instr_code
);
    reg [31:0] instruction_rom[0:(`INSTR_MEM_WORDS)-1];

    initial begin
        #1;
        $readmemh("instruction_code.mem",instruction_rom);
    end

    assign instr_code = instruction_rom[instr_addr[31:2]]; // byte align -> word align
endmodule
