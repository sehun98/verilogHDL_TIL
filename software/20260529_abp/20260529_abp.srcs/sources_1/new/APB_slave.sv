`timescale 1ns / 1ps

module APB_slave (
    //BUS Global signal
    input PCLK,

    //APB_interface slave
    input  logic [31:0] PADDR,
    input  logic [31:0] PWDATA,
    input  logic        PENABLE,
    input  logic        PWRITE,
    input  logic        PSEL,
    output              PREADY,
    output       [31:0] PRDATA
);
    logic [31:0] bram [0:63];

    assign PREADY0 = PENABLE & PSEL ? 1'b1 : 1'b0;
    assign PRDATA = bram[PADDR[31:2]];

    always_ff @(posedge PCLK) begin
        if(PWRITE & PREADY) begin
            bram[PADDR[31:2]] = PWDATA;
        end
    end
endmodule
