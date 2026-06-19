`timescale 1ns / 1ps

module tb_spi_top ();

  // --- 신호 선언 ---
  logic       clk;
  logic       reset;
  logic       start;
  logic [7:0] clk_div;
  logic [7:0] master_tx_data;
  logic [7:0] slave_tx_data;
  logic       cpol;
  logic       cpha;

  logic       master_done;
  logic       slave_done;
  logic [7:0] master_rx_data;
  logic [7:0] slave_rx_data;

  // DUT 연결
  spi_top dut(.*);

  // 1. 클록 생성 (100MHz 주기)
  always #5 clk = ~clk;

  // 2. SPI 모드 설정 태스크
  task spi_set_mode(bit [1:0] mode);
    {cpol, cpha} = mode;
    @(posedge clk);
  endtask

  // 3. Slave 송신 데이터 사전 준비 태스크
  task spi_slave_tx_data(logic [7:0] s_data);
    slave_tx_data = s_data;
    @(posedge clk); // 데이터를 버스에 미리 대기시킴
  endtask

  // 4. Master 송신 및 전체 전송 구동 태스크
  task spi_master_tx_data(logic [7:0] m_data);
    master_tx_data = m_data;
    start = 1'b1;
    @(posedge clk);
    start = 1'b0;
    @(posedge clk);
    wait (master_done); // done을 master_done으로 수정
    @(posedge clk);
  endtask

  // --- 시뮬레이션 시나리오 ---
  initial begin
    // 초기화
    clk   = 0;
    reset = 1;
    start = 0;
    clk_div = 0;
    master_tx_data = 0;
    slave_tx_data  = 0;
    
    repeat (3) @(posedge clk);
    reset = 0;
    @(posedge clk);
    
    clk_div = 4; // SCLK 속도 결정
    @(posedge clk);

    // Mode 00 설정
    spi_set_mode(2'b00);
    
    // Slave가 응답할 데이터 미리 채워두기 (예: 0x55)
    spi_slave_tx_data(8'h55);
    
    // Master가 0xAA를 보내면서 통신 시작 및 대기
    spi_master_tx_data(8'haa);

    spi_slave_tx_data(8'hFF);
    
    // Master가 0xAA를 보내면서 통신 시작 및 대기
    spi_master_tx_data(8'h7a);

    // Mode 01 설정
    spi_set_mode(2'b01);
    // Slave가 응답할 데이터 미리 채워두기 (예: 0x55)
    spi_slave_tx_data(8'h55);
    
    // Master가 0xAA를 보내면서 통신 시작 및 대기
    spi_master_tx_data(8'haa);

    spi_slave_tx_data(8'hFF);
    
    // Master가 0xAA를 보내면서 통신 시작 및 대기
    spi_master_tx_data(8'h7a);
    
    // Mode 02 설정
    spi_set_mode(2'b10);
    // Slave가 응답할 데이터 미리 채워두기 (예: 0x55)
    spi_slave_tx_data(8'h55);
    
    // Master가 0xAA를 보내면서 통신 시작 및 대기
    spi_master_tx_data(8'haa);

    spi_slave_tx_data(8'hFF);
    
    // Master가 0xAA를 보내면서 통신 시작 및 대기
    spi_master_tx_data(8'h7a);

    // Mode 02 설정
    spi_set_mode(2'b11);
    // Slave가 응답할 데이터 미리 채워두기 (예: 0x55)
    spi_slave_tx_data(8'h55);
    
    // Master가 0xAA를 보내면서 통신 시작 및 대기
    spi_master_tx_data(8'haa);

    spi_slave_tx_data(8'hFF);
    
    // Master가 0xAA를 보내면서 통신 시작 및 대기
    spi_master_tx_data(8'h7a);

    #20;
    $finish;
  end

endmodule