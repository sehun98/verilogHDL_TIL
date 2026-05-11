`timescale 1ns / 1ps


module fifo (
    input  logic       clk,
    input  logic       rst_n,
    input  logic [7:0] push_data,
    output logic [7:0] pop_data,
    input  logic       push,
    input  logic       pop,
    output  logic       full,
    output  logic       empty
);

logic [3:0] w_waddr, w_raddr;
logic w_we;
assign w_we = (~full & push);

register_file u1_register_file (
    .clk(clk),
    .wdata(push_data),
    .rdata(pop_data),

    .waddr(w_waddr),
    .raddr(w_raddr),
    .we(w_we)
);

register_control_unit u2_register_control_unit (
    .clk(clk),
    .rst_n(rst_n),
    .wptr(w_waddr),
    .rptr(w_raddr),
    .full(full),
    .empty(empty),

    .push(push),
    .pop(pop)
);

/*
    .*,
    .wptr(),
    .rptr()
*/

endmodule
