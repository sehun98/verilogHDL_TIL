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
    typedef enum logic [1:0] {
        IDLE, START, DATA, STOP
    }state_t;

    state_t state, next_state;

    reg [3:0] baud_cnt_reg, baud_cnt_next;
    reg [2:0] bit_cnt_reg, bit_cnt_next;
    reg [7:0] tx_data_reg, tx_data_next;
    reg tx_reg, tx_next;

    //==================================================
    // 1. Sequential Logic
    //==================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state       <= IDLE;
            baud_cnt_reg <= 0;
            bit_cnt_reg  <= 0;
            tx_data_reg  <= 0;
            tx_reg       <= 1'b1;
        end else begin
            state       <= next_state;
            baud_cnt_reg <= baud_cnt_next;
            bit_cnt_reg  <= bit_cnt_next;
            tx_data_reg  <= tx_data_next;
            tx_reg       <= tx_next;
        end
    end

    //==================================================
    // 2. Combinational Logic
    //==================================================
    always @(*) begin
        next_state    = state;
        baud_cnt_next = baud_cnt_reg;
        bit_cnt_next  = bit_cnt_reg;
        tx_data_next  = tx_data_reg;
        tx_next       = tx_reg;
        case (state)
            IDLE: begin
                tx_next       = 1'b1;
                baud_cnt_next = 0;
                bit_cnt_next  = 0;
                if (tx_send) begin
                    next_state   = START;
                    tx_data_next = tx_data;
                end
            end
            START: begin
                tx_next = 1'b0;
                if (tx_baud_tick) begin
                    if (baud_cnt_reg == 15) begin
                        baud_cnt_next = 0;
                        next_state    = DATA;
                    end else begin
                        baud_cnt_next = baud_cnt_reg + 1;
                    end
                end
            end
            DATA: begin
                tx_next = tx_data_reg[bit_cnt_reg];
                if (tx_baud_tick) begin
                    if (baud_cnt_reg == 15) begin
                        baud_cnt_next = 0;
                        if (bit_cnt_reg == 7) begin
                            bit_cnt_next = 0;
                            next_state   = STOP;
                        end else begin
                            bit_cnt_next = bit_cnt_reg + 1;
                        end
                    end else begin
                        baud_cnt_next = baud_cnt_reg + 1;
                    end
                end
            end
            STOP: begin
                tx_next = 1'b1;
                if (tx_baud_tick) begin
                    if (baud_cnt_reg == 15) begin
                        baud_cnt_next = 0;
                        next_state    = IDLE;
                    end else begin
                        baud_cnt_next = baud_cnt_reg + 1;
                    end
                end
            end
        endcase
    end
    assign tx = tx_reg;
    assign tx_busy = (state != IDLE);
    assign tx_overrun_error = (state != IDLE) && tx_send;
endmodule