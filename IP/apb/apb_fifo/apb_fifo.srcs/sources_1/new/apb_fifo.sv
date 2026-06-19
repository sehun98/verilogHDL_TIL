`timescale 1ns / 1ps

module apb_fifo (
    input logic PCLK,
    input logic PRESETn,
    input logic 
);


    register_file u1_register_file (
        .clk(clk),
        .we(we),
        .raddr(raddr),
        .waddr(waddr),
        .wdata(wdata),
        .rdata(rdata)
    );

    fifo_control_unit u2_fifo_control_unit (
        .clk  (clk),
        .rst_n(rst_n),
        .wptr (wptr),
        .rptr (rptr),
        .push (push),
        .pull (pull),
        .full (full),
        .empty(empty)
    );
endmodule

module register_file (
    input  logic       clk,
    input  logic       we,
    input  logic [7:0] raddr,
    input  logic [7:0] waddr,
    input  logic [7:0] wdata,
    output logic [7:0] rdata
);
    logic [7:0] register_file[0:255];

    always_ff @(posedge clk) begin
        if (we) begin
            register_file[waddr] <= wdata;
        end
    end
    assign rdata = register_file[raddr];
endmodule

module fifo_control_unit (
    input  logic       clk,
    input  logic       rst_n,
    output logic [7:0] wptr,
    output logic [7:0] rptr,
    input  logic       push,
    input  logic       pull,
    output logic       full,
    output logic       empty
);
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rptr  <= 8'd0;
            wptr  <= 8'd0;
            full  <= 1'b0;
            empty <= 1'b1;
        end else begin
            case ({
                push, pull
            })
                2'b01: begin
                    if (!empty) begin
                        rptr <= rptr + 1'b1;
                        full <= 1'b0;
                        if (rptr + 1'b1 == wptr) empty <= 1'b1;
                    end
                end
                2'b10: begin
                    if (!full) begin
                        wptr  <= wptr + 1'b1;
                        empty <= 1'b0;
                        if (wptr + 1'b1 == rptr) full <= 1'b1;
                    end
                end
                2'b11: begin
                    if (full) begin
                        rptr <= rptr + 1'b1;
                        full <= 1'b0;
                    end else if (empty) begin
                        wptr  <= wptr + 1'b1;
                        empty <= 1'b0;
                    end else begin
                        wptr <= wptr + 1'b1;
                        rptr <= rptr + 1'b1;
                    end
                end
            endcase
        end
    end
endmodule
