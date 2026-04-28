`timescale 1ns / 1ps

module register_control_unit (
    input wire clk,
    input wire rst_n,

    output wire [1:0] w_ptr,
    output wire [1:0] r_ptr,

    output reg full,
    output reg empty,

    input wire push,
    input wire pop
);

reg [1:0] w_ptr_next, w_ptr_reg;
reg [1:0] r_ptr_next, r_ptr_reg;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        full <= 0;
        empty <= 1;
        w_ptr_reg <= 0;
        r_ptr_reg <= 0;
    end else begin
        w_ptr_reg <= w_ptr_next;
        r_ptr_reg <= r_ptr_next;
    end
end

always @(*) begin
    
        if(push && !full) begin
            if(w_ptr_next == r_ptr_reg)
            w_ptr <= w_ptr + 1;
        end
        if(pop) begin
            
        end
end

endmodule


/* 
register_file_no_latency #(
    parameter  REG_SIZE  = 4,
    localparam ADDR_SIZE = $clog2(REG_SIZE)
) (
    input  wire                 clk,
    input  wire [          7:0] w_data,
    output wire [          7:0] r_data,
    input  wire [ADDR_SIZE-1:0] w_addr,  // 0~3
    input  wire [ADDR_SIZE-1:0] r_addr,  // 0~3
    input  wire                 w_en
);


*/
