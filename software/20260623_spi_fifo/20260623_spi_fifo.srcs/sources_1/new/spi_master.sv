`timescale 1ns / 1ps

module spi_master(
    input logic clk,
    input logic rst_n,

    input logic SPI_CR,
    output logic SPI_SR,
    input logic [31:0] SPI_DR,
    );
endmodule
