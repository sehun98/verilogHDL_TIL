`timescale 1ns / 1ps
// ====================================================
// UART_TX_Controller
// [동작 구조]
// 1. 이벤트 입력
//    - error_send           : 에러 메시지 전송 요청
//    - watch_time_request   : 시계 시간 전송 요청
//    - ultrasonic_done      : 초음파 거리 측정 완료 후 전송 요청
//    - dht11_done           : 온습도 측정 완료 후 전송 요청
//
// 2. FSM 동작
//    - IDLE 상태에서 이벤트를 감지하여 해당 상태로 전이
//    - 각 상태에서 message buffer를 기반으로 문자열을 순차 전송
//    - 전송 완료 시 IDLE로 복귀
//
//    상태 종류:
//      IDLE → 대기 상태
//      ERROR_SEND → "ERROR\n"
//      WATCH_TIME_REQUEST → "WATCH HH:MM:SS:MS\n"
//      ULTRASONIC_DONE → "DISTANCE XXX\n"
//      DHT11_DONE → "TEMP XX HUM XX\n"
// =======================================================
module UART_TX_Controller (
    input wire clk,
    input wire rst_n,

    input wire error_send,
    input wire watch_time_request,
    input wire ultrasonic_done,
    input wire dht11_done,

    input wire [4:0] i_hour_data,
    input wire [5:0] i_min_data,
    input wire [5:0] i_sec_data,
    input wire [6:0] i_msec_data,

    input wire [7:0] i_temp_data,
    input wire [7:0] i_humidity_data,
    input wire [8:0] i_distance_data,

    input wire fifo_full,
    output wire fifo_w_en,
    output wire [7:0] fifo_data
);
    // FSM
    localparam IDLE = 3'b000;
    localparam ERROR_SEND = 3'b001;
    localparam WATCH_TIME_REQUEST = 3'b010;
    localparam ULTRASONIC_DONE = 3'b011;
    localparam DHT11_DONE = 3'b100;

    reg [3:0] state, n_state;

    // buffer
    // 8*length
    wire [ 8*6-1:0] error_buffer;
    wire [8*18-1:0] watch_time_buffer;
    wire [8*27-1:0] ultrasonic_buffer;
    wire [8*29-1:0] dht11_buffer;

    // message length count
    // 0~31
    reg [4:0] cnt_reg, cnt_next;

    // uart tx controller to tx fifo data
    reg [7:0] fifo_data_reg, fifo_data_next;

    // uart tx controller to tx fifo enable
    reg fifo_w_en_reg, fifo_w_en_next;

    // error message
    assign error_buffer[7:0]          = "E";
    assign error_buffer[15:8]         = "R";
    assign error_buffer[23:16]        = "R";
    assign error_buffer[31:24]        = "O";
    assign error_buffer[39:32]        = "R";
    assign error_buffer[47:40]        = 8'h0A;

    // watch HH:MM:SS:MS message
    assign watch_time_buffer[7:0]     = "W";
    assign watch_time_buffer[15:8]    = "A";
    assign watch_time_buffer[23:16]   = "T";
    assign watch_time_buffer[31:24]   = "C";
    assign watch_time_buffer[39:32]   = "H";
    assign watch_time_buffer[47:40]   = " ";
    assign watch_time_buffer[55:48]   = i_hour_data / 10 + "0";  // 1
    assign watch_time_buffer[63:56]   = i_hour_data % 10 + "0";  // 2
    assign watch_time_buffer[71:64]   = ":";  // :
    assign watch_time_buffer[79:72]   = i_min_data / 10 + "0";  // 0
    assign watch_time_buffer[87:80]   = i_min_data % 10 + "0";  // 0
    assign watch_time_buffer[95:88]   = ":";  // :
    assign watch_time_buffer[103:96]  = i_sec_data / 10 + "0";  // 0
    assign watch_time_buffer[111:104] = i_sec_data % 10 + "0";  // 0
    assign watch_time_buffer[119:112] = ":";  // :
    assign watch_time_buffer[127:120] = i_msec_data / 10 + "0";  // 0
    assign watch_time_buffer[135:128] = i_msec_data % 10 + "0";  // 0
    assign watch_time_buffer[143:136] = 8'h0A;

    // [HH:MM:SS:MS] distance XXX message
    assign ultrasonic_buffer[7:0]     = "[";
    assign ultrasonic_buffer[15:8]    = i_hour_data / 10 + "0";  // 1
    assign ultrasonic_buffer[23:16]   = i_hour_data % 10 + "0";  // 2
    assign ultrasonic_buffer[31:24]   = ":";  // :
    assign ultrasonic_buffer[39:32]   = i_min_data / 10 + "0";  // 0
    assign ultrasonic_buffer[47:40]   = i_min_data % 10 + "0";  // 0
    assign ultrasonic_buffer[55:48]   = ":";  // :
    assign ultrasonic_buffer[63:56]   = i_sec_data / 10 + "0";  // 0
    assign ultrasonic_buffer[71:64]   = i_sec_data % 10 + "0";  // 0
    assign ultrasonic_buffer[79:72]   = ":";  // :
    assign ultrasonic_buffer[87:80]   = i_msec_data / 10 + "0";  // 0
    assign ultrasonic_buffer[95:88]   = i_msec_data % 10 + "0";  // 0
    assign ultrasonic_buffer[103:96]  = "]";
    assign ultrasonic_buffer[111:104] = " ";
    assign ultrasonic_buffer[119:112] = "D";
    assign ultrasonic_buffer[127:120] = "I";
    assign ultrasonic_buffer[135:128] = "S";
    assign ultrasonic_buffer[143:136] = "T";
    assign ultrasonic_buffer[151:144] = "A";
    assign ultrasonic_buffer[159:152] = "N";
    assign ultrasonic_buffer[167:160] = "C";
    assign ultrasonic_buffer[175:168] = "E";
    assign ultrasonic_buffer[183:176] = " ";
    assign ultrasonic_buffer[191:184] = i_distance_data / 100 + "0";
    assign ultrasonic_buffer[199:192] = (i_distance_data / 10) % 10 + "0";
    assign ultrasonic_buffer[207:200] = i_distance_data % 10 + "0";
    assign ultrasonic_buffer[215:208] = 8'h0A;



    // [HH:MM:SS:MS] temp XX, hum XX message
    assign dht11_buffer[7:0]     = "[";
    assign dht11_buffer[15:8]    = i_hour_data / 10 + "0";  // 1
    assign dht11_buffer[23:16]   = i_hour_data % 10 + "0";  // 2
    assign dht11_buffer[31:24]   = ":";  // :
    assign dht11_buffer[39:32]   = i_min_data / 10 + "0";  // 0
    assign dht11_buffer[47:40]   = i_min_data % 10 + "0";  // 0
    assign dht11_buffer[55:48]   = ":";  // :
    assign dht11_buffer[63:56]   = i_sec_data / 10 + "0";  // 0
    assign dht11_buffer[71:64]   = i_sec_data % 10 + "0";  // 0
    assign dht11_buffer[79:72]   = ":";  // :
    assign dht11_buffer[87:80]   = i_msec_data / 10 + "0";  // 0
    assign dht11_buffer[95:88]   = i_msec_data % 10 + "0";  // 0
    assign dht11_buffer[103:96]  = "]";
    assign dht11_buffer[111:104] = " ";
    assign dht11_buffer[119:112] = "T";
    assign dht11_buffer[127:120] = "E";
    assign dht11_buffer[135:128] = "M";
    assign dht11_buffer[143:136] = "P";
    assign dht11_buffer[151:144] = " ";
    assign dht11_buffer[159:152] = i_temp_data / 10 + "0";
    assign dht11_buffer[167:160] = i_temp_data % 10 + "0";
    assign dht11_buffer[175:168] = " ";
    assign dht11_buffer[183:176] = "H";
    assign dht11_buffer[191:184] = "U";
    assign dht11_buffer[199:192] = "M";
    assign dht11_buffer[207:200] = " ";
    assign dht11_buffer[215:208] = i_humidity_data / 10 + "0";
    assign dht11_buffer[223:216] = i_humidity_data % 10 + "0";
    assign dht11_buffer[231:224] = 8'h0A;

    assign fifo_data                  = fifo_data_reg;
    assign fifo_w_en                  = fifo_w_en_reg;

    // 1. state register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state         <= IDLE;
            fifo_data_reg <= 0;
            cnt_reg       <= 0;
            fifo_w_en_reg <= 0;
        end else begin
            state         <= n_state;
            fifo_data_reg <= fifo_data_next;
            cnt_reg       <= cnt_next;
            fifo_w_en_reg <= fifo_w_en_next;
        end
    end

    // 2. next state combinational logic 
    always @(*) begin
        n_state        = state;
        fifo_data_next = fifo_data_reg;
        cnt_next       = cnt_reg;
        fifo_w_en_next = fifo_w_en_reg;
        case (state)
            IDLE: begin
                if (error_send) begin
                    n_state = ERROR_SEND;
                end else if (watch_time_request) begin
                    n_state = WATCH_TIME_REQUEST;
                end else if (ultrasonic_done) begin
                    n_state = ULTRASONIC_DONE;
                end else if (dht11_done) begin
                    n_state = DHT11_DONE;
                end
            end

            ERROR_SEND: begin
                if (!fifo_full) begin
                    if (cnt_reg == 6) begin
                        n_state = IDLE;
                        cnt_next = 0;
                        fifo_w_en_next = 0;
                    end else begin
                        fifo_w_en_next = 1;
                        fifo_data_next = error_buffer[8*cnt_reg+:8];
                        cnt_next = cnt_reg + 1;
                    end
                end
            end

            WATCH_TIME_REQUEST: begin
                if (!fifo_full) begin
                    if (cnt_reg == 18) begin
                        n_state = IDLE;
                        cnt_next = 0;
                        fifo_w_en_next = 0;
                    end else begin
                        fifo_w_en_next = 1;
                        fifo_data_next = watch_time_buffer[8*cnt_reg+:8];
                        cnt_next = cnt_reg + 1;
                    end
                end
            end

            ULTRASONIC_DONE: begin
                if (!fifo_full) begin
                    if (cnt_reg == 27) begin
                        n_state = IDLE;
                        cnt_next = 0;
                        fifo_w_en_next = 0;
                    end else begin
                        fifo_w_en_next = 1;
                        fifo_data_next = ultrasonic_buffer[8*cnt_reg+:8];
                        cnt_next = cnt_reg + 1;
                    end
                end
            end

            DHT11_DONE: begin
                if (!fifo_full) begin
                    if (cnt_reg == 29) begin
                        n_state = IDLE;
                        cnt_next = 0;
                        fifo_w_en_next = 0;
                    end else begin
                        fifo_w_en_next = 1;
                        fifo_data_next = dht11_buffer[8*cnt_reg+:8];
                        cnt_next = cnt_reg + 1;
                    end
                end
            end
        endcase
    end


endmodule
