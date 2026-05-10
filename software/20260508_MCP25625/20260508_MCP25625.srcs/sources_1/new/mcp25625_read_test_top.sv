`timescale 1ns / 1ps

module mcp25625_read_test_top (
    input logic clk,
    input logic rst_n,

    // MCP25625 physical pins
    input  logic INT,
    output logic CS,
    output logic SCK,
    output logic MOSI,
    input  logic MISO,

    // debug output
    output logic [7:0] canstat_debug
);

    logic       sck;

    logic [7:0] spi_tx_data;
    logic [7:0] spi_rx_data;
    logic       spi_request;
    logic       spi_done;

    // =========================================================
    // SCK Generator
    // =========================================================
    sck_gen #(
        .CLOCK_FREQ_HZ(100_000_000),
        .BAUD_RATE    (500_000)
    ) u_sck_gen (
        .clk  (clk),
        .rst_n(rst_n),
        .sck  (sck)
    );

    // =========================================================
    // SPI Master
    // =========================================================
    spi_master u_spi_master (
        .clk  (clk),
        .rst_n(rst_n),

        .tx_data(spi_tx_data),
        .rx_data(spi_rx_data),

        .request(spi_request),
        .done   (spi_done),
        .sck    (sck),

        .SCK (SCK),
        .MOSI(MOSI),
        .MISO(MISO)
    );

    // =========================================================
    // CANSTAT Read Test Controller
    // =========================================================
    mcp25625_can_test u_mcp25625_can_test (
        .clk  (clk),
        .rst_n(rst_n),

        .CS(CS),

        .spi_tx_data(spi_tx_data),
        .spi_rx_data(spi_rx_data),
        .spi_request(spi_request),
        .spi_done   (spi_done),

        .canstat_debug(canstat_debug)
    );

    ila_0 ila_0_test (
        .clk(clk),
        .probe0(CS),
        .probe1(SCK),
        .probe2(MOSI),
        .probe3(MISO),
        .probe4(spi_tx_data),
        .probe5(spi_rx_data),
        .probe6(spi_request),
        .probe7(spi_done),
        .probe8(canstat_debug)
    );

endmodule
