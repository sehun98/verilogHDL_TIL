`timescale 1ns / 1ps

module instruction_memory (
    input  wire [31:0] instr_addr,
    output wire [31:0] instr_code
);
    reg [31:0] instruction_rom[0:255]; // 명령어 줄 수
`ifdef TEST_SIMULATION
    initial begin
        instruction_rom[0] = 32'h0031_02b3;
    end
`endif 
    initial begin
        $readmemh("instruction_code.mem",instruction_rom);
    end
    assign instr_code = instruction_rom[instr_addr[31:2]]; // byte align -> word align
endmodule