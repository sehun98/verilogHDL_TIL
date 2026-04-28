`timescale 1ns / 1ps

module fifo (
    input  wire       clk,
    input  wire       reset,
    input  wire [7:0] push_data,
    input  wire       push,
    input  wire       pop,
    output      [7:0] pop_data,
    output            full,
    output            empty
);



endmodule

module register_file #(
    parameter FILE_SIZE = 4
) (
    input wire       clk,
    input wire [1:0] waddr,
    input wire [1:0] raddr,
    input wire [7:0] wdata,
    input wire [7:0] rdata,
    input wire       we
);
    reg [7:0] register_file[0:FILE_SIZE-1];

    always @(posedge clk) begin
        if (we) begin
            register_file[waddr] <= wdata;
        end
    end

    assign rdata = register_file[raddr];

endmodule

module control_unit (
    input  wire       clk,
    input  wire       reset,
    input  wire       push,
    input  wire       pop,
    output wire [1:0] wptr,
    output wire [1:0] rptr,
    output wire       full,
    output wire       empty
);
    reg [1:0] wptr_reg, wptr_next;
    reg [1:0] rptr_reg, rptr_next;

    always @(posedge clk or negedge reset) begin
        if(!reset) begin
            wptr_reg <= 0;
            rptr_reg <= 0;
        end else begin
            wptr_reg <= wptr_next;
            rptr_reg <= rptr_next;
        end
    end


endmodule

