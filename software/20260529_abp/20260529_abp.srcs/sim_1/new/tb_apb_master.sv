`timescale 1ns / 1ps


module tb_apb_master ();
    logic        PCLK;
    logic        PRESET;
    logic [31:0] ADDR;
    logic [31:0] WDATA;
    logic        R_REQ;
    logic        W_REQ;
    logic [31:0] RDATA;
    logic        READY;
    logic [31:0] PADDR;
    logic [31:0] PWDATA;
    logic        PENABLE;
    logic        PWRITE;
    logic        PSEL0;
    logic        PSEL1;
    logic        PSEL2;
    logic        PSEL3;
    logic        PSEL4;
    logic        PREADY0;
    logic        PREADY1;
    logic        PREADY2;
    logic        PREADY3;
    logic        PREADY4;
    logic [31:0] PRDATA0;
    logic [31:0] PRDATA1;
    logic [31:0] PRDATA2;
    logic [31:0] PRDATA3;
    logic [31:0] PRDATA4;

    APB_master dut (.*);

    always #5 PCLK = ~PCLK;

    initial begin
        PCLK   = 0;
        PRESET = 1;
        @(negedge PCLK);
        @(negedge PCLK);
        PRESET = 0;

        @(posedge PCLK);
        #1;
        ADDR  = 32'h1000_0000;
        WDATA = 32'h0A0A_5050;
        W_REQ = 1'b1;
        R_REQ = 1'b0;

        @(PENABLE & PSEL0)
        PREADY0 = 1'b1;
        @(posedge PCLK);
    end

endmodule
