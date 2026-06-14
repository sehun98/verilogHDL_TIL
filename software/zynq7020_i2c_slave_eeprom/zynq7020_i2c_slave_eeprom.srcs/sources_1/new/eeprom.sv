`timescale 1ns / 1ps

module eeprom (
    input logic       clk,
    input logic       rst_n,
    input logic [2:0] chip_select,
    input logic       scl,
    inout wire        sda
);

    logic       w_we;
    logic [7:0] w_addr;
    logic [7:0] w_rdata;
    logic [7:0] w_wdata;

    i2c_slave_eeprom u1_i2c_slave_eeprom (
        .clk        (clk),
        .rst_n      (rst_n),
        .chip_select(chip_select),
        .we         (w_we),
        .addr       (w_addr),
        .rdata      (w_rdata),
        .wdata      (w_wdata),
        .scl        (scl),
        .sda        (sda)
    );

    eeprom_data_path u2_eeprom_data_path (
        .clk  (clk),
        .we   (w_we),
        .addr (w_addr),
        .rdata(w_rdata),
        .wdata(w_wdata)
    );
endmodule
