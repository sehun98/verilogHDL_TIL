`timescale 1ns / 1ps

module uart_command_parser (
    input wire clk,
    input wire rst_n,

    // receive
    input wire [7:0] rx_din,
    output wire rx_r_en,
    input wire rx_empty,

    // transmitter
    input wire [7:0] tx_dout,
    output wire tx_w_en,
    input wire tx_full,

    output wire led
);
    // 1. if(!empty) recieve data 
    // 2. if(buff \n 존재) parser 진행
    // 3. compare command and convert command code
    // 4. 

    // 1. S_IDLE : rx_empty == 0 이면 rx_r_en = 1 발생
    // 2. S_RX_REQ : 
    // 3. S_RX_DATA : 
    // 4. S_RX_PARSE : 
    // 5. S_PARSE :
    // 6. S_RX_DATA : 
    // 7. S_PARSE : 
    // 8. S_EXEC : 
    // 9. S_TX_SEND : 
endmodule
