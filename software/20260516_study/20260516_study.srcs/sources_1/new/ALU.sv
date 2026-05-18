`timescale 1ns / 1ps

module ALU (
    input wire [7:0] a,
    input wire [7:0] b,
    input wire [2:0] op_code,  // + - | & ^ ~ 
    output wire zero_flag,
    output reg [7:0] out
);
    typedef enum logic [2:0] { // 111
        ADD, SUB, OR, AND, XOR, NOT, BUFF
    } op_code_t;
    
    always_comb begin
        case(op_code)
            ADD : out = a + b;
            SUB : out = a - b;
            OR : out = a | b;
            AND : out = a & b;
            XOR : out = a ^ b;
            NOT : out = ~a;
            BUFF : out = a;
            default : out = a;
        endcase
    end
    assign zero_flag = (out == 8'h00);
endmodule
