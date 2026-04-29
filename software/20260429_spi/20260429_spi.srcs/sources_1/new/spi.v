`timescale 1ns / 1ps

module spi (
    input wire clk,
    input wire rst_n,
    input wire sck_square,
    input wire sck_rising_tick,
    input wire sck_falling_tick,

    input wire send,
    output wire done,

    input  wire [7:0] tx_data,
    output wire [7:0] rx_data,

    output wire MOSI,
    input  wire MISO,
    output wire CS,
    output wire SCK
);

    localparam S_IDLE = 2'b00;
    // sck falling 대기 state
    localparam S_START = 2'b01;
    localparam S_DATA = 2'b10;
    localparam S_STOP = 2'b11;

    reg [1:0] c_state, n_state;  // 0~3

    reg sck_en_reg, sck_en_next;

    // CPOL = 0 ,LOW 
    assign SCK = sck_en_reg & sck_square;

    // 0~7 111
    reg [2:0] bit_cnt_reg, bit_cnt_next;

    reg cs_reg, cs_next;

    assign CS = cs_reg;

    reg [7:0] tx_data_reg, tx_data_next;
    reg [7:0] rx_data_reg, rx_data_next;

    reg MOSI_reg, MOSI_next;

    assign MOSI    = MOSI_reg;
    assign rx_data = rx_data_reg;

    reg done_reg, done_next;
    
    assign done = done_reg;

    // 1. state register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            c_state <= S_IDLE;
            sck_en_reg <= 0;
            bit_cnt_reg <= 0;
            cs_reg <= 1;
            tx_data_reg <= 0;
            rx_data_reg <= 0;
            MOSI_reg <= 0;
            done_reg <= 0;
        end else begin
            c_state <= n_state;
            sck_en_reg <= sck_en_next;
            bit_cnt_reg <= bit_cnt_next;
            cs_reg <= cs_next;
            tx_data_reg <= tx_data_next;
            rx_data_reg <= rx_data_next;
            MOSI_reg <= MOSI_next;
            done_reg <= done_next;
        end
    end

    // 2. state next combinational logic
    always @(*) begin
        n_state = c_state;
        case (c_state)
            S_IDLE:  if (send) n_state = S_START;
            S_START: if (sck_falling_tick) n_state = S_DATA;
            S_DATA:  if (sck_falling_tick  && bit_cnt_reg == 7) n_state = S_STOP;
            S_STOP:  n_state = S_IDLE;
            default: n_state = c_state;
        endcase
    end

    // 3. sck control combinational logic
    always @(*) begin
        sck_en_next = sck_en_reg;
        case (c_state)
            S_IDLE:  sck_en_next = 0;
            S_START: sck_en_next = 0;
            S_DATA:  sck_en_next = 1;
            S_STOP:  sck_en_next = 0;
            default: sck_en_next = 0;
        endcase
    end

    // 4. bit_cnt next combinational logic
    // 수신 후 송신이 마친 시점 falling에서 cnt 증가 
    always @(*) begin
        bit_cnt_next = bit_cnt_reg;
        case (c_state)
            S_IDLE:  bit_cnt_next = 0;
            S_START: bit_cnt_next = 0;
            S_DATA: begin
                if (sck_falling_tick) begin
                    if (bit_cnt_reg == 7) begin
                        bit_cnt_next = 0;
                    end else begin
                        bit_cnt_next = bit_cnt_reg + 1;
                    end
                end
            end
            S_STOP:  bit_cnt_next = 0;
            default: bit_cnt_next = bit_cnt_reg;
        endcase
    end

    // 5. CS active low
    always @(*) begin
        cs_next = cs_reg;
        case (n_state)
            S_IDLE:  if(send) cs_next = 0; else cs_next = 1;
            S_START: cs_next = 0;
            S_DATA:  cs_next = 0;
            S_STOP:  cs_next = 0;
            default: cs_next = 1;
        endcase
    end

    // 6. tx shift
    // falling 시점에 송신을 위한 데이터 준비
    always @(*) begin
        tx_data_next = tx_data_reg;

        case (c_state)
            S_IDLE: begin
                if (send) tx_data_next = tx_data;
            end

            S_DATA: begin
                if (sck_falling_tick) tx_data_next = {tx_data_reg[6:0], 1'b0};
            end
        endcase
    end

    // MOSI
    // falling 시점에 송신
    always @(*) begin
        MOSI_next = MOSI_reg;

        case (c_state)
            S_IDLE: begin
                if (send) MOSI_next = tx_data[7];  // 첫 비트 미리 출력
            end

            S_DATA: begin
                if (sck_falling_tick)
                    MOSI_next = tx_data_reg[6];   // shift 전 기준 다음 비트
            end

            S_STOP: MOSI_next = 1'b0;
        endcase
    end

    // RX
    // rising 시점에서 수신
    always @(*) begin
        rx_data_next = rx_data_reg;

        case (c_state)
            S_IDLE: begin
                if (send) rx_data_next = 8'd0;
            end

            S_DATA: begin
                if (sck_rising_tick) rx_data_next = {rx_data_reg[6:0], MISO};
            end
        endcase
    end

    // done
    // done의 시점 : 
    always @(*) begin
        done_next = done_reg;
        case (c_state)
            S_IDLE:  done_next = 0;
            S_START: done_next = 0;
            S_DATA:  done_next = 0;
            S_STOP:  done_next = 1;
            default: done_next = 0;
        endcase
    end
endmodule
