`timescale 1ns / 1ps

// FIFO_CR
// [0] EN
// [1] CLR
// [31:2] reserved

// FIFO_SR 
// [0] EMPTY
// [1] FULL
// [2] ALMOST_EMPTY
// [3] ALMOST_FULL
// [7:4] reserved
// [15:8] COUNT
// [31:16] reserved

// FIFO_DR

module fifo_core (
    input  logic        clk,
    input  logic        rst_n,
    input  logic [31:0] FIFO_CR,
    output logic [31:0] FIFO_SR,
    input  logic [31:0] FIFO_WDATA,
    output logic [31:0] FIFO_RDATA,
    input  logic        push,
    input  logic        pop
);
    logic empty;
    logic full;
    logic almost_empty;
    logic almost_full;
    logic [7:0] count;

    logic [7:0] wptr;
    logic [7:0] rptr;

    logic en;
    logic clear;

    assign en = FIFO_CR[0];
    assign clear = FIFO_CR[1];

    assign FIFO_SR[0] = empty;
    assign FIFO_SR[1] = full;
    assign FIFO_SR[2] = almost_empty;
    assign FIFO_SR[3] = almost_full;
    assign FIFO_SR[15:8] = count;

    fifo_data_path u1_fifo_data_path (
        .clk  (clk),
        .we   (push & !full),
        .waddr(wptr),
        .raddr(rptr),
        .wdata(FIFO_WDATA),
        .rdata(FIFO_RDATA)
    );

    fifo_control_unit u2_fifo_control_unit (
        .clk         (clk),
        .rst_n       (rst_n),
        .wptr        (wptr),
        .rptr        (rptr),
        .full        (full),
        .empty       (empty),
        .almost_full (almost_full),
        .almost_empty(almost_empty),
        .count       (count),
        .en          (en),
        .clear       (clear),
        .push        (push),
        .pop         (pop)
    );
endmodule

module fifo_data_path (
    input  logic        clk,
    input  logic        we,
    input  logic [ 7:0] waddr,
    input  logic [ 7:0] raddr,
    input  logic [15:0] wdata,
    output logic [15:0] rdata
);
    logic [15:0] register_file[0:255];
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
    output logic       full,
    output logic       empty,
    output logic       almost_full,
    output logic       almost_empty,
    output logic [7:0] count,
    input  logic       en,
    input  logic       clear,
    input  logic       push,
    input  logic       pop
);
    localparam ALMOST_EMPTY_THRESHOLD = 25;
    localparam ALMOST_FULL_THRESHOLD = 230;

    assign almost_empty = (count <= ALMOST_EMPTY_THRESHOLD);
    assign almost_full = (count >= ALMOST_FULL_THRESHOLD);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n || clear) begin
            wptr <= 8'd0;
            rptr <= 8'd0;
            full <= 1'b0;
            empty <= 1'b1;
            almost_full <= 1'b0;
            almost_empty <= 1'b0;
            count <= 8'd0;
        end else begin
            if (en) begin
                case ({
                    push, pop
                })
                    2'b01: begin
                        if (!empty) begin
                            rptr  <= rptr + 8'd1;
                            full  <= 1'b0;
                            empty <= ((rptr + 8'd1) == wptr);
                            count <= count - 8'd1;
                        end
                    end
                    2'b10: begin
                        if (!full) begin
                            wptr  <= wptr + 8'd1;
                            empty <= 1'b0;
                            full  <= ((wptr + 8'd1) == rptr);
                            count <= count + 8'd1;
                        end
                    end
                    2'b11: begin
                        if (full) begin
                            rptr  <= rptr + 8'd1;
                            full  <= 1'b0;
                            count <= count - 8'd1;
                        end
                        if (empty) begin
                            wptr  <= wptr + 8'd1;
                            empty <= 1'b0;
                            count <= count + 8'd1;
                        end else begin
                            rptr <= rptr + 8'd1;
                            wptr <= wptr + 8'd1;
                        end
                    end
                endcase
            end
        end
    end

endmodule

