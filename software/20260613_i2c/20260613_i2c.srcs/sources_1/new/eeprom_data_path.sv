`timescale 1ns / 1ps

module eeprom_data_path (
    input  logic       clk,
    input  logic       we,
    input  logic [7:0] addr,
    output logic [7:0] rdata,
    input  logic [7:0] wdata
);
    logic [7:0] eeprom[0:255];

    always_ff @(posedge clk) begin
        if (we) begin
            eeprom[addr] <= wdata;
        end
    end
    assign rdata = eeprom[addr];
endmodule
