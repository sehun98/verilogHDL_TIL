`timescale 1ns / 1ps

// dht11에 fnd랑 btn이 모두 있으면 X
// top_stopwatch에서 연결됨.
module dht11 (
    input  clk,
    input  rst,

    input dht11_start, // uart tx controller에서 dht11 데이터 요청 신호
    output dht11_done, // uart tx controller로 보내는 읽으라는 pulse 신호
    
    output [7:0] humidity, // uart tx controller로 보내는 데이터
    output [7:0] temperature, // uart tx controller로 보내는 데이터
    inout  dht11 // 입출력 라인
);
endmodule

// valid 가 1일 경우에면 done신호가 발생해야되고 외부로 valid를 보낼 필요가 없어짐.
module dht11_controller (
    input            clk,
    input            rst,
    input            tick_us,

    input            dht11_start,
    output reg       dht11_done,

    output     [7:0] humidity,
    output     [7:0] temperature,
    inout            dht11
);

endmodule

module tick_gen_us (
    input clk,
    input rst,
    output reg tick_us
);

endmodule