`timescale 1ns / 1ps

module spi_top (
    input logic clk,
    input logic reset,

    input  logic       start,           // Master 전송 시작 신호
    input  logic [7:0] clk_div,         // SCLK 속도 분주값
    input  logic [7:0] master_tx_data,  // Master가 Slave로 보낼 데이터
    input  logic [7:0] slave_tx_data,   // Slave 가 Master로 보낼 데이터
    input  logic       cpol,
    input  logic       cpha,
    output logic       master_done,     // Master 통신 완료 플래그
    output logic       slave_done,      // Slave 통신 완료 플래그
    output logic [7:0] master_rx_data,  // Master가 최종 수신한 데이터
    output logic [7:0] slave_rx_data    // Slave가 최종 수신한 데이터
);

  logic sclk;
  logic mosi;
  logic miso;
  logic ss_n;

  logic master_busy;

  spi_master U_SPI_MASTER (
      // global signals
      .clk    (clk),
      .reset  (reset),
      // internal signals
      .start  (start),
      .cpol   (cpol),
      .cpha   (cpha),
      .clk_div(clk_div),
      .tx_data(master_tx_data),
      .busy   (master_busy),
      .rx_data(master_rx_data),
      .done   (master_done),
      // external signals
      .sclk   (sclk),
      .mosi   (mosi),
      .miso   (miso),
      .ss_n   (ss_n)
  );

  spi_slave U_SPI_SLAVE (
      .clk    (clk),
      .reset  (reset),
      // internal signals
      .tx_data(slave_tx_data),  // Slave가 Master로 보낼 데이터 꽂아줌
      .rx_data(slave_rx_data),  // Master로부터 수신된 데이터가 쌓이는 곳
      .done   (slave_done),     // Slave 단독 완료 신호 연결
      .cpol   (cpol),
      .cpha   (cpha),
      // external signals (버스 연결)
      .sclk   (sclk),
      .mosi   (mosi),
      .miso   (miso),
      .ss_n   (ss_n)
  );

endmodule
