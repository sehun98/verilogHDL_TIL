`timescale 1ns / 1ps
`include "define.vh"

module rv32i_datapath ();

endmodule

module register_file (
    input wire clk,

    input wire reg_w_en,
    // address
    input wire [4:0] raddr1,
    input wire [4:0] raddr2,
    input wire [4:0] waddr,

    // data
    input  wire [31:0] wdata,
    output wire [31:0] rdata1,
    output wire [31:0] rdata2
);

    reg [31:0] register_file[1:31];

    // byte addressing -> word addressing
    always_ff @(posedge clk) begin
        if (reg_w_en) begin
            register_file[waddr[31:2]] <= wdata;
        end
    end

    assign rdata1 = (raddr1 == 5'd0) ? 32'd0 : register_file[raddr1[31:2]];
    assign rdata2 = (raddr2 == 5'd0) ? 32'd0 : register_file[raddr2[31:2]];
endmodule

// zero, carry, sign, overflow flag
module alu (
    input wire [31:0] a,
    input wire [31:0] b,
    input wire [4:0] alu_control,  // funct7[5], funct7[0], funct3[2:0]
    output wire b_taken,
    output wire [31:0] alu_result
);
    wire [31:0] add_result;
    wire [31:0] sub_result;
    wire [31:0] sll_result;
    wire [31:0] slt_result;
    wire [31:0] sltu_result;
    wire [31:0] xor_result;
    wire [31:0] srl_result;
    wire [31:0] sra_result;
    wire [31:0] or_result;
    wire [31:0] and_result;

    wire [63:0] mul_ss_result;
    wire [63:0] mul_su_result;
    wire [63:0] mul_uu_result;

    wire [31:0] div_result;
    wire [31:0] divu_result;
    wire [31:0] rem_result;
    wire [31:0] remu_result;

    reg [31:0] alu_result_reg;
    reg b_taken_reg;

    assign alu_result = alu_result_reg;
    assign b_taken = b_taken_reg;

    assign add_result = a + b;
    assign sub_result = a - b;
    assign sll_result = a << b[4:0];
    assign slt_result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
    assign sltu_result = ($unsigned(a) < $unsigned(b)) ? 32'd1 : 32'd0;
    assign xor_result = a ^ b;
    assign srl_result = $unsigned(a) >> b[4:0];
    assign sra_result = $signed(a) >>> b[4:0];
    assign or_result = a | b;
    assign and_result = a & b;

    assign mul_ss_result = $signed(a) * $signed(b);
    assign mul_su_result = $signed(a) * $unsigned(b);
    assign mul_uu_result = $unsigned(a) * $unsigned(b);

    assign div_result = (b == 0) ? 32'hFFFF_FFFF :
                     (a == 32'h8000_0000 && b == 32'hFFFF_FFFF) ? 32'h8000_0000 :
                     $signed(a) / $signed(b);
    assign divu_result = (b == 0) ? 32'hFFFF_FFFF :
                     $unsigned(a) / $unsigned(b);
    assign rem_result = (b == 0) ? a :
                     (a == 32'h8000_0000 && b == 32'hFFFF_FFFF) ? 32'd0 : $signed(a) % $signed(b);
    assign remu_result = (b == 0) ? a : $unsigned(a) % $unsigned(b);

    always_comb begin
        alu_result_reg = 32'd0;
        case (alu_control)  // 5bit
            `ADD:  alu_result_reg = add_result;
            `SUB:  alu_result_reg = sub_result;
            `SLL:  alu_result_reg = sll_result;
            `SLT:  alu_result_reg = slt_result;
            `SLTU: alu_result_reg = sltu_result;
            `XOR:  alu_result_reg = xor_result;
            `SRL:  alu_result_reg = srl_result;
            `SRA:  alu_result_reg = sra_result;
            `OR:   alu_result_reg = or_result;
            `AND:  alu_result_reg = and_result;
        
            `MUL: alu_result_reg = mul_uu_result[31:0];
            `MULH: alu_result_reg = mul_ss_result[63:32];
            `MULHSU: alu_result_reg = mul_su_result[63:32];
            `MULHU: alu_result_reg = mul_uu_result[63:32];
            `DIV: alu_result_reg = div_result;
            `DIVU: alu_result_reg = divu_result;
            `REM: alu_result_reg = rem_result;
            `REMU: alu_result_reg = remu_result;
        endcase
    end

    always_comb begin
        b_taken_reg = 1'b0;
        case(alu_control[2:0])
            `BEQ: b_taken_reg = (a == b);
            `BNE: b_taken_reg = (a != b);
            `BLT: b_taken_reg = ($signed(a) < $signed(b));
            `BGE: b_taken_reg = ($signed(a) >= $signed(b));
            `BLTU: b_taken_reg = ($unsigned(a) < $unsigned(b));
            `BGEU: b_taken_reg = ($unsigned(a) >= $unsigned(b));
        endcase
    end
endmodule

// enable, bubble, flush, 
module pipeline_register(
    input wire clk,
    input wire [31:0] din,
    /*
    input wire en,
    input wire bubble,
    input wire flush,
    */
    output wire [31:0] dout
);
    reg [31:0] dout_reg;

    assign dout = dout_reg;
    
    always_ff @(posedge clk) begin
        dout_reg <= din;
    end
    /*
    always_ff @(posedge clk) begin
        if(flush) begin
            dout_reg <= 32'd0;
        end else if(bubble) begin
            dout_reg <= 32'd0;
        end else if(en) begin
            dout_reg <= din;
        end
    end
    */
endmodule