`timescale 1ns / 1ps

module instruction_memory (
    input  wire [31:0] instr_addr,
    output wire [31:0] instr_code
);
    reg [31:0] instruction_rom[0:63];
    initial begin
        instruction_rom[0] = 32'h0031_02b3;
        instruction_rom[1] = 32'h0041_82b3;
        instruction_rom[2] = 32'h0031_2123;
        instruction_rom[3] = 32'h0021_2403;
        instruction_rom[4] = 32'h0043_8413;
        instruction_rom[5] = 32'hFE84_0CE3;
        instruction_rom[6] = 32'h0031_02b3;
    end
    assign instr_code = instruction_rom[instr_addr[31:2]]; // byte align -> word align
endmodule