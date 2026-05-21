`timescale 1ns / 1ps

module rv32i_datapath(

    );
endmodule

module register_file(
    input wire clk,

    // control unit
    input wire reg_we,

    // instruction memory
    input wire [5:0] rs1,
    input wire [5:0] rs2,
    input wire [5:0] rd,
    
    // data memory
    input wire [31:0] wdata,
    
    // alu
    output wire [31:0] rdata1,
    output wire [31:0] rdata2
);
    reg [31:0] register_file[1:31];

    always_ff @(posedge clk) begin
        if(reg_we) begin
            register_file[rd] = wdata;
        end
    end

    assign rdata1 = (rs1==32'd0) ? 32'd0 : register_file[rs1]; 
    assign rdata2 = (rs2==32'd0) ? 32'd0 : register_file[rs2]; 
endmodule

