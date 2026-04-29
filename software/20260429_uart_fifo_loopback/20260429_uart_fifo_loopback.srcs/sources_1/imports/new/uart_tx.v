`timescale 1ns / 1ps

module uart_tx (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       tx_baud_tick,
    input  wire [7:0] tx_data,
    input  wire       tx_send,
    output wire       tx_busy,
    output wire       tx_overrun_error,
    output wire       tx
);
    localparam IDLE = 2'b00;
    localparam START = 2'b01;
    localparam DATA = 2'b10;
    localparam STOP = 2'b11;

    reg [1:0] state, n_state;
    reg [3:0] tx_baud_tick_cnt_reg, tx_baud_tick_cnt_next;
    reg [2:0] tx_bit_cnt_reg, tx_bit_cnt_next;
    reg [7:0] tx_data_reg, tx_data_next;
    reg tx_reg, tx_next;
    reg tx_busy_reg;
    wire tx_busy_next;
    reg tx_overrun_error_reg;
    wire tx_overrun_error_next;

    assign tx = tx_reg;

    // 1. register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            tx_baud_tick_cnt_reg <= 0;
            tx_bit_cnt_reg <= 0;
            tx_data_reg <= 0;
            tx_reg <= 1;
            tx_busy_reg <= 0;
            tx_overrun_error_reg <= 0;
        end else begin
            state <= n_state;
            tx_baud_tick_cnt_reg <= tx_baud_tick_cnt_next;
            tx_bit_cnt_reg <= tx_bit_cnt_next;
            tx_data_reg <= tx_data_next;
            tx_reg <= tx_next;
            tx_busy_reg <= tx_busy_next;
            tx_overrun_error_reg <= tx_overrun_error_next;
        end
    end

    // 2.0 data lode 
    always @(*) begin
        tx_data_next = tx_data_reg;
        case (state)
            IDLE: if (tx_send) tx_data_next = tx_data;
            START: tx_data_next = tx_data_reg;
            DATA: tx_data_next = tx_data_reg;
            STOP: tx_data_next = tx_data_reg;
            default: tx_data_next = tx_data_reg;
        endcase
    end

    // 2. next state combinational logic
    always @(*) begin
        n_state = state;
        case (state)
            IDLE: if (tx_send) n_state = START;
            START:
            if (tx_baud_tick && tx_baud_tick_cnt_reg == 15) n_state = DATA;
            DATA:
            if (tx_baud_tick && tx_baud_tick_cnt_reg == 15) begin
                if (tx_bit_cnt_reg == 7) begin
                    n_state = STOP;
                end else begin
                    n_state = DATA;
                end
            end
            STOP:
            if (tx_baud_tick && tx_baud_tick_cnt_reg == 15) n_state = IDLE;
            default: n_state = state;
        endcase
    end

    // 3. baud tick cnt combinational logic
    always @(*) begin
        tx_baud_tick_cnt_next = tx_baud_tick_cnt_reg;
        case (state)
            IDLE: tx_baud_tick_cnt_next = 0;
            START: begin
                if (tx_baud_tick) begin
                    if (tx_baud_tick_cnt_reg == 15) tx_baud_tick_cnt_next = 0;
                    else tx_baud_tick_cnt_next = tx_baud_tick_cnt_reg + 1;
                end
            end
            DATA: begin
                if (tx_baud_tick) begin
                    if (tx_baud_tick_cnt_reg == 15) tx_baud_tick_cnt_next = 0;
                    else tx_baud_tick_cnt_next = tx_baud_tick_cnt_reg + 1;
                end
            end
            STOP: begin
                if (tx_baud_tick) begin
                    if (tx_baud_tick_cnt_reg == 15) tx_baud_tick_cnt_next = 0;
                    else tx_baud_tick_cnt_next = tx_baud_tick_cnt_reg + 1;
                end
            end
            default: tx_baud_tick_cnt_next = tx_baud_tick_cnt_reg;
        endcase
    end

    // 4. bit cnt combinational logic
    always @(*) begin
        tx_bit_cnt_next = tx_bit_cnt_reg;
        case (state)
            IDLE: tx_bit_cnt_next = 0;
            START: tx_bit_cnt_next = 0;
            DATA:
            if (tx_baud_tick && tx_baud_tick_cnt_reg == 15) begin
                if (tx_bit_cnt_reg == 7) begin
                    tx_bit_cnt_next = 0;
                end else begin
                    tx_bit_cnt_next = tx_bit_cnt_reg + 1;
                end
            end
            STOP: tx_bit_cnt_next = 0;
            default: tx_bit_cnt_next = 0;
        endcase
    end

    // 5. output combinational logic tx_data_reg
    always @(*) begin
        tx_next = tx_reg;
        case (state)
            IDLE: tx_next = 1;
            START: tx_next = 0;  // start bit
            DATA: tx_next = tx_data_reg[tx_bit_cnt_reg];
            STOP: tx_next = 1;  // stop bit
            default: tx_next = tx_reg;
        endcase
    end

    // tx_busy는 현재 클럭에서 START로 진입하는 순간 바로 1이 되어야 하므로
    // 현재 state가 아니라 next state 기준으로 생성한다.
    assign tx_busy_next = (n_state != IDLE);

    // overrun_error는 이미 송신 중인 상태에서 tx_send가 다시 들어온 경우만 검출해야 한다.
    // n_state 기준으로 판단하면 IDLE에서 정상 tx_send로 START에 진입하는 경우도
    // overrun으로 오검출되므로 현재 state 기준으로 생성한다.
    assign tx_overrun_error_next = (state != IDLE) && tx_send;

    assign tx_busy = tx_busy_reg;
    assign tx_overrun_error = tx_overrun_error_reg;

endmodule
