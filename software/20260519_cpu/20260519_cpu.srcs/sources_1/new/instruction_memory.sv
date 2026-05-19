`timescale 1ns / 1ps

module instruction_memory (
    input  wire [31:0] instr_addr,
    output wire [31:0] instr_code
);
    reg [31:0] instruction_rom[0:63];

    initial begin
        instruction_rom[0] = 32'h0031_02b3; // x5 = x2 + x3
        instruction_rom[1] = 32'h0041_82b3; // x5 = x4 + x3
    end

    assign instr_code = instruction_rom[instr_addr[31:2]]; // byte align -> word align
endmodule
