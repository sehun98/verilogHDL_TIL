`timescale 1ns / 1ps
// error_send pulse 신호를 받는다.
// fifo_full 이 아니면
// fifo_data = "ERROR\n"
// fifo_w_en 시도 
// 

// time을
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

    input wire fifo_full,
    output wire fifo_w_en,
    output wire [7:0] fifo_data
);
    wire [ 8*6-1:0] error_buffer;  // 8*count ERROR\n 6
    wire [8*18-1:0] watch_time_buffer;  // 8*count ERROR\n 6

    reg [4:0] cnt_reg, cnt_next;  // 0~31

    localparam IDLE = 3'b000;
    localparam ERROR_SEND = 3'b001;
    localparam WATCH_TIME_REQUEST = 3'b010;
    localparam ULTRASONIC_DONE = 3'b011;
    localparam DTH11_DONE = 3'b011;

    reg [3:0] state, n_state;

    // error\n
    // 39:32 31:24 23:16 15:8 7:0
    assign error_buffer[7:0] = "E";
    assign error_buffer[15:8] = "R";
    assign error_buffer[23:16] = "R";
    assign error_buffer[31:24] = "O";
    assign error_buffer[39:32] = "R";
    assign error_buffer[47:40] = 8'h0A;

    assign watch_time_buffer[7:0] = "W";
    assign watch_time_buffer[15:8] = "A";
    assign watch_time_buffer[23:16] = "T";
    assign watch_time_buffer[31:24] = "C";
    assign watch_time_buffer[39:32] = "H";
    assign watch_time_buffer[47:40] = " ";

    assign watch_time_buffer[55:48] = i_hour_data / 10 + "0";  // 1
    assign watch_time_buffer[63:56] = i_hour_data % 10 + "0";  // 2
    assign watch_time_buffer[71:64] = ":";  // :
    assign watch_time_buffer[79:72] = i_min_data / 10 + "0";  // 0
    assign watch_time_buffer[87:80] = i_min_data % 10 + "0";  // 0
    assign watch_time_buffer[95:88] = ":";  // :
    assign watch_time_buffer[103:96] = i_sec_data / 10 + "0";  // 0
    assign watch_time_buffer[111:104] = i_sec_data % 10 + "0";  // 0
    assign watch_time_buffer[119:112] = ":";  // :
    assign watch_time_buffer[127:120] = i_msec_data / 10 + "0";  // 0
    assign watch_time_buffer[135:128] = i_msec_data % 10 + "0";  // 0

    assign watch_time_buffer[143:136] = 8'h0A;

    reg [7:0] fifo_data_reg, fifo_data_next;
    reg fifo_w_en_reg, fifo_w_en_next;

    assign fifo_data = fifo_data_reg;
    assign fifo_w_en = fifo_w_en_reg;

    // 1. state register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            fifo_data_reg <= 0;
            cnt_reg <= 0;
            fifo_w_en_reg <= 0;
        end else begin
            state <= n_state;
            fifo_data_reg <= fifo_data_next;
            cnt_reg <= cnt_next;
            fifo_w_en_reg <= fifo_w_en_next;
        end
    end

    // 2. next state combinational logic 
    always @(*) begin
        n_state = state;
        fifo_data_next = fifo_data_reg;
        cnt_next = cnt_reg;
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
                    n_state = DTH11_DONE;
                end
            end
            ERROR_SEND: begin
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

            // 18
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
                
            end
        endcase
    end

endmodule
