`timescale 1ns / 1ps

module fifo #(
    parameter  DEPTH     = 16,
    localparam BIT_WIDTH = $clog2(DEPTH)
) (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [7:0] push_data,
    input  wire       push,
    input  wire       pop,
    output wire [7:0] pop_data,
    output wire       full,
    output wire       empty
);

    wire [BIT_WIDTH-1:0] w_waddr;
    wire [BIT_WIDTH-1:0] w_raddr;

    register_file #(
        .DEPTH(DEPTH)
    ) u1_register_file (
        .clk(clk),
        .waddr(w_waddr),
        .raddr(w_raddr),
        .wdata(push_data),
        .rdata(pop_data),
        .we   ((~full) & push)
    );

    register_control_unit #(
        .DEPTH(DEPTH)
    ) u2_register_control_unit (
        .clk  (clk),
        .rst_n(rst_n),
        .push (push),
        .pop  (pop),
        .wptr (w_waddr),
        .rptr (w_raddr),
        .full (full),
        .empty(empty)
    );

endmodule