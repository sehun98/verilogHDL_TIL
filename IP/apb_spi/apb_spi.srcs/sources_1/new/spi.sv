`timescale 1ns / 1ps
/*
 * SPI_CR
 * DFF : 8bit / 16bit
 * LSBFIRST : MSB First / LSB First
 * BR[2:0] : 2 / 4 / 8 / 16 / 32 / 64 / 128 / 256
 * MSTR : Slave / Master
 * CPOL : 0 / 1
 * CPHA : 0 / 1
 *
 *
 * SPI_SR
 * BSY : busy flag
 * OVR : Overrun flag
 * TXE : Transmit buffer empty
 * RXNE : Receive buffer not empty
 *
 * SPI_DR
 * DR[15:0] : Data register
 * 
 * 
 */

module spi_master (
    input logic clk,
    input logic rst_n,

    input  logic [31:0] SPI_CR,
    output logic [31:0] SPI_SR,
    inout  logic [31:0] SPI_DR,

    output logic mosi,
    input  logic miso,
    output logic sclk,
    output logic cs
);
    logic DFF;
    logic LSBFIRST;
    logic [2:0] BR;
    logic MSTR;
    logic CPOL;
    logic CPHA;

    assign START = SPI_CR[8];
    assign DFF = SPI_CR[7];
    assign LSBFIRST = SPI_CR[6];
    assign BR = SPI_CR[5:3];
    assign MSTR = SPI_CR[2];
    assign CPOL = SPI_CR[1];
    assign CPHA = SPI_CR[0];

    logic BSY;
    logic OVR;
    logic TXE;
    logic RXNE;

    assign BSY  = SPI_SR[3];
    assign OVR  = SPI_SR[2];
    assign TXE  = SPI_SR[1];
    assign RXNE = SPI_SR[0];

    logic tick;

    // ?
    logic [15:0] tx_data;
    logic [15:0] rx_data;

    // ?
    assign SPI_DR = {16'd0, tx_data};

    /*
     * start bit가 들어오면
     * baudrate에 따라 동작
     */
    reg [15:0] tx_shift_reg;

    typedef enum logic [1:0] {
        IDLE,
        DATA,
        DONE
    } state_t;

    state_t state;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            BSY  <= 1'b0;
            OVR  <= 1'b0;
            TXE  <= 1'b0;
            RXNE <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    BSY  <= 1'b0;
                    OVR  <= 1'b0;
                    TXE  <= 1'b0;
                    RXNE <= 1'b0;
                    if (START) begin
                        tx_shift_reg <= tx_data;
                    end
                end
                DATA: begin

                end
                DONE: begin

                end
            endcase
        end
    end

    baudrate u1_baudrate (
        .clk  (clk),
        .rst_n(rst_n),
        .BR   (BR),
        .tick (tick)
    );
endmodule

/*
 * 000 : 2
 * 001 : 4
 * 010 : 8
 * 011 : 16
 * 100 : 32
 * 101 : 64
 * 110 : 128
 * 111 : 256
 */
module baudrate (
    input logic clk,
    input logic rst_n,
    input logic [2:0] BR,
    output logic tick
);
    localparam CLOCK_FREQ_HZ = 100_000_000;

    logic [31:0] cnt;
    logic [31:0] count;

    always_comb begin
        case (BR)
            3'd0: count = 2;
            3'd1: count = 4;
            3'd2: count = 8;
            3'd3: count = 16;
            3'd4: count = 32;
            3'd5: count = 64;
            3'd6: count = 128;
            3'd7: count = 256;
            default: count = 2;
        endcase
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt  <= 32'd0;
            tick <= 1'b0;
        end else begin
            if (cnt == count - 1) begin
                cnt  <= 32'd0;
                tick <= 1'b1;
            end else begin
                cnt  <= cnt + 1'b1;
                tick <= 1'b0;
            end
        end
    end

endmodule

module fifo(
    input logic clk,
    input logic [32:0] tx_data,
    output logic [32:0] rx_data,
    output logic empty,
    output logic full,
    input logic push,
    input logic pup
);

    

endmodule

module register_file(
    input logic clk,
    input logic we,
    input logic [31:0] addr,
    input logic [31:0] tx_data,

)