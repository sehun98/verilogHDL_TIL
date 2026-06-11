`timescale 1ns / 1ps

module apb_timer(
    input logic PCLK,
    input logic PRESETn,

    input logic PSEL,
    input logic PENABLE,
    input logic PWRITE,
    input logic [3:0] PSTRB,
    input logic [31:0] PADDR,
    input logic [31:0] PWDATA,

    output logic [31:0] PRDATA,
    output logic PREADY,
    output logic PSLVERR,

    output logic 
    );

    // CR1 control register 0x00
    // CR2 0x04
    // CKD[1:0] ARPE CMS[1:0] DIR OPM URS UDIS CEN
    // SMCR 0x08
    // DIER 0x0C
    // SR 0x10
    // EGR 0x14
    // CCMR 0x18
    // CCMR 0x1C
    // CCER 0x20
    // CNT 0x24
    // PSC prescale 0x28
    // ARR 0x2C
    // RCR 0x30
    // CCR1 0x34
    logic apb_setup;
    logic apb_access;
    logic apb_read;
    logic apb_write;

    logic []

    assign apb_setup = PSEL & !PENABLE;
    assign apb_access = PSEL & PENABLE;
    assign apb_read = apb_access & !PWRITE;
    assign apb_write = apb_access & PWRITE;

    always_ff @(posedge PCLK or negedge PRESETn) begin
        if(!PRESETn) begin

        end else begin


        end
    end

endmodule
