`timescale 1ns / 1ps
`include "define.vh"

module rv32i_datapath (
    input  wire         clk,
    input  wire         rst_n,
    input  wire  [31:0] instr_code,
    input  wire         register_file_we,
    input  logic [ 9:0] alu_control,
    output wire  [31:0] instr_addr
);
    wire [31:0] w_rdata0;
    wire [31:0] w_rdata1;
    wire [31:0] w_alu_result;

    rv32i_register_file u1_rv32i_register_file (
        .clk(clk),

        // control unit
        .raddr0          (instr_code[19:15]),
        .raddr1          (instr_code[24:20]),
        .waddr           (instr_code[11:7]),
        .register_file_we(register_file_we),

        // alu
        .wdata (w_alu_result),
        .rdata0(w_rdata0),
        .rdata1(w_rdata1)
    );

    rv32i_alu u2_rv32i_alu (
        .a          (w_rdata0),
        .b          (w_rdata1),
        .alu_control(alu_control),
        .alu_result (w_alu_result)
    );

    rv32i_process_counter u3_rv32i_process_counter (
        .clk(clk),
        .rst_n(rst_n),
        .pc_in(instr_addr),
        .pc_out(instr_addr)
    );

endmodule

module rv32i_register_file (
    input wire clk,

    // instruction memory
    input wire [4:0] raddr0,  // 32
    input wire [4:0] raddr1,
    input wire [4:0] waddr,

    // control unit
    input wire register_file_we,

    // feedback
    input wire [31:0] wdata,

    // alu
    output wire [31:0] rdata0,
    output wire [31:0] rdata1
);
    reg [31:0] mem[1:31];

    initial begin
        for (int i = 0; i < 32; i = i + 1) begin
            mem[i] = i;
        end
    end

    always_ff @(posedge clk) begin
        if (register_file_we) begin
            mem[waddr] <= wdata;
        end
    end

    assign rdata0 = (raddr0 == 5'd0) ? 32'd0 : mem[raddr0];
    assign rdata1 = (raddr1 == 5'd0) ? 32'd0 : mem[raddr1];
endmodule

module rv32i_alu (
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire [ 9:0] alu_control,
    output wire [31:0] alu_result
);
    reg [31:0] alu_result_reg;

    always_comb begin
        alu_result_reg = 32'd0;
        case (alu_control)
            `ADD:  alu_result_reg = a + b;
            `SUB:  alu_result_reg = a - b;
            `SLL: alu_result_reg = a << b[4:0]; // 2^5 =32 a<<b; 
            `SLT:  alu_result_reg = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
            `SLTU: alu_result_reg = ($unsigned(a) < $unsigned(b)) ? 32'd1 : 32'd0;  // zero-extention
            `XOR:  alu_result_reg = a ^ b;
            `SRL: alu_result_reg = a >> b[4:0]; // a>>b;
            `SRA: alu_result_reg = $signed(a) >> b[4:0]; // a>>b; // msb-extention
            `OR:   alu_result_reg = a | b;
            `AND:  alu_result_reg = a & b;
        endcase
    end
    assign alu_result = alu_result_reg;
endmodule

module rv32i_process_counter (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [31:0] pc_in,
    output wire [31:0] pc_out
);
    reg [31:0] mem;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mem <= 32'd0;
        end else begin
            mem <= pc_in + 32'd4;
        end
    end
    assign pc_out = mem;
endmodule
