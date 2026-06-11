`timescale 1ns / 1ps

module apb_fifo (
    input logic PCLK,
    input logic PRESETn,

    input logic PSEL,
    input logic PENABLE,
    input logic PWRITE,
    input logic [3:0] PSTRB,
    input logic [31:0] PWDATA,
    input logic [31:0] PADDR,

    output logic [31:0] PRDATA,
    output logic PREADY,
    output logic PSLVERR,

    output logic [7:0] tx_fifo_push_data,
    output logic tx_fifo_push,

    input logic [7:0] rx_fifo_pull_data,
    output logic rx_fifo_pull,
    
    input logic tx_fifo_full,
    input logic rx_fifo_empty,

    input logic tx_overrun_error,
    input logic rx_frame_error
);
    logic apb_setup;
    logic apb_access;
    logic apb_read;
    logic apb_write;

    assign apb_setup = PSEL & !PENABLE;
    assign apb_access = PSEL & PENABLE;
    assign apb_read = apb_access & !PWRITE;
    assign apb_write = apb_access & PWRITE;

    // 0x00 : SR
    // 0x04 : DR
    // 0x08 : BRR
    // 0x0C : CR1
    // 0x10 : CR2
    // 0x14 : CR3
    // 0x18 : GTPR

    always_ff @(posedge PCLK or negedge PENABLE) begin
        if(!PRESETn) begin

        end else begin

        end
    end

endmodule
