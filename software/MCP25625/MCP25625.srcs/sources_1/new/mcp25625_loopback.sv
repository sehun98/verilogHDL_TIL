`timescale 1ns / 1ps

module mcp25625_loopback (
    input logic clk,
    input logic rst_n,

    // MCP25625 physical pins
    input  logic INT,
    output logic CS,
    output logic SCK,
    output logic MOSI,
    input  logic MISO
);
    logic        sck;

    logic [ 7:0] spi_tx_data;
    logic [ 7:0] spi_rx_data;
    logic        spi_request;
    logic        spi_done;

    logic        tx_request;
    logic        tx_busy;

    logic        rx_ready;
    logic        rx_valid;

    logic [10:0] rx_id;
    logic [ 3:0] rx_dlc;
    logic [ 7:0] rx_data0;
    logic [ 7:0] rx_data1;
    logic [ 7:0] rx_data2;
    logic [ 7:0] rx_data3;
    logic [ 7:0] rx_data4;
    logic [ 7:0] rx_data5;
    logic [ 7:0] rx_data6;
    logic [ 7:0] rx_data7;

    logic [10:0] tx_id;
    logic [ 3:0] tx_dlc;
    logic [ 7:0] tx_data0;
    logic [ 7:0] tx_data1;
    logic [ 7:0] tx_data2;
    logic [ 7:0] tx_data3;
    logic [ 7:0] tx_data4;
    logic [ 7:0] tx_data5;
    logic [ 7:0] tx_data6;
    logic [ 7:0] tx_data7;

    // =========================================================
    // Echo buffer
    // =========================================================
    logic [10:0] echo_id_reg;
    logic [ 3:0] echo_dlc_reg;
    logic [ 7:0] echo_data0_reg;
    logic [ 7:0] echo_data1_reg;
    logic [ 7:0] echo_data2_reg;
    logic [ 7:0] echo_data3_reg;
    logic [ 7:0] echo_data4_reg;
    logic [ 7:0] echo_data5_reg;
    logic [ 7:0] echo_data6_reg;
    logic [ 7:0] echo_data7_reg;

    logic        echo_pending;

    assign tx_id    = echo_id_reg;
    assign tx_dlc   = echo_dlc_reg;
    assign tx_data0 = echo_data0_reg;
    assign tx_data1 = echo_data1_reg;
    assign tx_data2 = echo_data2_reg;
    assign tx_data3 = echo_data3_reg;
    assign tx_data4 = echo_data4_reg;
    assign tx_data5 = echo_data5_reg;
    assign tx_data6 = echo_data6_reg;
    assign tx_data7 = echo_data7_reg;
    // 수정
    assign rx_ready = !echo_pending && !tx_busy;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            echo_id_reg    <= 11'd0;
            echo_dlc_reg   <= 4'd0;
            echo_data0_reg <= 8'd0;
            echo_data1_reg <= 8'd0;
            echo_data2_reg <= 8'd0;
            echo_data3_reg <= 8'd0;
            echo_data4_reg <= 8'd0;
            echo_data5_reg <= 8'd0;
            echo_data6_reg <= 8'd0;
            echo_data7_reg <= 8'd0;

            echo_pending <= 1'b0;
            tx_request   <= 1'b0;
        end else begin
            tx_request <= 1'b0;

            // RX frame capture
            if (rx_valid && rx_ready) begin
                echo_id_reg    <= rx_id;
                echo_dlc_reg   <= rx_dlc;
                echo_data0_reg <= rx_data0;
                echo_data1_reg <= rx_data1;
                echo_data2_reg <= rx_data2;
                echo_data3_reg <= rx_data3;
                echo_data4_reg <= rx_data4;
                echo_data5_reg <= rx_data5;
                echo_data6_reg <= rx_data6;
                echo_data7_reg <= rx_data7;

                echo_pending <= 1'b1;
            end
            // 기존
            // if (echo_pending && !tx_busy) begin

            // 수정
            // TX request 1clk pulse
            if (echo_pending && !tx_busy && INT) begin
                tx_request   <= 1'b1;
                echo_pending <= 1'b0;
            end
        end
    end

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
    // MCP25625 Controller
    // =========================================================
    mcp25625_controller u_mcp25625_controller (
        .clk  (clk),
        .rst_n(rst_n),

        .INT(INT),
        .CS (CS),

        .rx_id   (rx_id),
        .rx_dlc  (rx_dlc),
        .rx_data0(rx_data0),
        .rx_data1(rx_data1),
        .rx_data2(rx_data2),
        .rx_data3(rx_data3),
        .rx_data4(rx_data4),
        .rx_data5(rx_data5),
        .rx_data6(rx_data6),
        .rx_data7(rx_data7),

        .rx_ready(rx_ready),
        .rx_valid(rx_valid),

        .tx_id   (tx_id),
        .tx_dlc  (tx_dlc),
        .tx_data0(tx_data0),
        .tx_data1(tx_data1),
        .tx_data2(tx_data2),
        .tx_data3(tx_data3),
        .tx_data4(tx_data4),
        .tx_data5(tx_data5),
        .tx_data6(tx_data6),
        .tx_data7(tx_data7),

        .tx_request(tx_request),
        .tx_busy   (tx_busy),

        .spi_tx_data(spi_tx_data),
        .spi_rx_data(spi_rx_data),
        .spi_request(spi_request),
        .spi_done   (spi_done)
    );
endmodule
