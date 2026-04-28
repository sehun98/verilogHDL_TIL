`timescale 1ns / 1ps
// IDLE, START, DATA, STOP

module uart_tx (
    input wire clk,
    input wire rst_n,
    input wire baud_tick,
    input wire [7:0] tx_data,
    input wire tx_send,
    output wire tx_busy,
    output wire tx_overrun_error,
    output wire tx
);

    localparam S_IDLE = 2'b00;
    localparam S_START = 2'b01;
    localparam S_DATA = 2'b10;
    localparam S_STOP = 2'b11;

    reg [1:0] c_state, n_state;

    // 0~15
    reg [3:0] baud_tick_cnt_reg, baud_tick_cnt_next;
    // 0~7
    reg [2:0] bit_cnt_reg, bit_cnt_next;

    reg [7:0] tx_data_reg, tx_data_next;

    reg tx_reg, tx_next;

    assign tx = tx_reg;

    reg  tx_busy_reg;
    wire tx_busy_next;

    // 1. state register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            c_state <= S_IDLE;
            baud_tick_cnt_reg <= 4'd0;
            bit_cnt_reg <= 3'd0;
            tx_data_reg <= 8'd0;
            tx_reg <= 1'b1;
            tx_busy_reg <= 1'b0;
        end else begin
            c_state <= n_state;
            baud_tick_cnt_reg <= baud_tick_cnt_next;
            bit_cnt_reg <= bit_cnt_next;
            tx_data_reg <= tx_data_next;
            tx_reg <= tx_next;
            tx_busy_reg <= tx_busy_next;
        end
    end

    // define tx_send is pulse signal
    // 2. next state combinationl logic
    always @(*) begin
        n_state = c_state;
        case (c_state)
            S_IDLE: if (tx_send) n_state = S_START;
            S_START: if (baud_tick && baud_tick_cnt_reg == 15) n_state = S_DATA;
            S_DATA:
            if (baud_tick && baud_tick_cnt_reg == 15 && bit_cnt_reg == 7)
                n_state = S_STOP;
            S_STOP: if (baud_tick && baud_tick_cnt_reg == 15) n_state = S_IDLE;
            default: n_state = c_state;
        endcase
    end

    // 3. baud tick cnt next combinational logic
    always @(*) begin
        baud_tick_cnt_next = baud_tick_cnt_reg;

        if (c_state == S_IDLE) begin
            baud_tick_cnt_next = 0;
        end else if (baud_tick) begin
            if (baud_tick_cnt_reg == 15) baud_tick_cnt_next = 0;
            else baud_tick_cnt_next = baud_tick_cnt_reg + 1;
        end
    end

    // 4. bit cnt next combinational logic
    always @(*) begin
        bit_cnt_next = bit_cnt_reg;
        case (c_state)
            S_IDLE:  bit_cnt_next = 0;
            S_START: bit_cnt_next = 0;
            S_DATA: begin
                if (baud_tick && baud_tick_cnt_reg == 15) begin
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

    // 5. output combinational logic
    always @(*) begin
        tx_data_next = tx_data_reg;
        case (c_state)
            S_IDLE:  if (tx_send) tx_data_next = tx_data;
            S_START: tx_data_next = tx_data_reg;
            S_DATA:  tx_data_next = tx_data_reg;
            S_STOP:  tx_data_next = tx_data_reg;
            default: tx_data_next = tx_data_reg;
        endcase
    end

    always @(*) begin
        tx_next = tx_reg;
        case (c_state)
            S_IDLE: begin
                if (tx_send) tx_next = 1'b0;
                else tx_next = 1'b1;
            end
            S_START: tx_next = 1'b0;
            S_DATA:  tx_next = tx_data_reg[bit_cnt_reg];
            S_STOP:  tx_next = 1'b1;
            default: tx_next = 1'b1;
        endcase
    end

    // 7. tx_busy combinational logic
    assign tx_busy_next = (n_state != S_IDLE);
    assign tx_busy = tx_busy_reg;

    assign tx_overrun_error = tx_send && tx_busy_reg;
endmodule
