`timescale 1ns / 1ps

module instruction_memory (
    input  wire [31:0] instr_addr,
    output wire [31:0] instr_code
);
    reg [31:0] instruction_rom[0:63];

    initial begin
        instruction_rom[0] = 32'h01F0_1023;
        //instruction_rom[1] = 32'h0011_2123;
        //instruction_rom[2] = 32'h402F_54B3;
        //instruction_rom[3] = 32'h0010_0133;
        //instruction_rom[4] = 32'h4011_0233;
        //instruction_rom[5] = 32'h0050_9333;
        //instruction_rom[6] = 32'h0030_92B3;
        //instruction_rom[7] = 32'h0030_A3B3;
        //instruction_rom[8] = 32'h0030_B433;
        //instruction_rom[9] = 32'h0011_C533;
        //instruction_rom[10] = 32'h0061_E5B3;
        //instruction_rom[11] = 32'h0061_F633;
    end

    assign instr_code = instruction_rom[instr_addr[31:2]]; // byte align -> word align
endmodule
