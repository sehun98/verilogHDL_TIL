`timescale 1ns / 1ps

module uart_rx (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       rx_baud_tick,
    input  wire       rx,
    output wire       rx_done,
    output wire [7:0] rx_data,
    output wire       rx_frame_error
);

    // IDLE, START, DATA, STOP
    localparam integer IDLE = 2'b00;
    localparam integer START = 2'b01;
    localparam integer DATA = 2'b10;
    localparam integer STOP = 2'b11;

    reg [1:0] state, n_state;

    reg sync_ff1, sync_ff2;
    reg [3:0] baud_tick_cnt_reg, baud_tick_cnt_next;  // 0~16
    reg [2:0] bit_cnt_reg, bit_cnt_next;  // 0~7
    reg [7:0] rx_data_reg, rx_data_next;
    reg rx_done_reg, rx_done_next;
    reg rx_frame_error_reg, rx_frame_error_next;

    // 1. state register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            baud_tick_cnt_reg <= 0;
            bit_cnt_reg <= 0;
            rx_data_reg <= 0;
            rx_done_reg <= 0;
            rx_frame_error_reg <= 0;
        end else begin
            state              <= n_state;
            baud_tick_cnt_reg  <= baud_tick_cnt_next;
            bit_cnt_reg        <= bit_cnt_next;
            rx_data_reg        <= rx_data_next;
            rx_done_reg        <= rx_done_next;
            rx_frame_error_reg <= rx_frame_error_next;
        end
    end

    // 2.0 rx syncronizer
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_ff1 <= 1'b1;
            sync_ff2 <= 1'b1;
        end else begin
            sync_ff1 <= rx;
            sync_ff2 <= sync_ff1;
        end
    end

    // 2. next state combinational logic
    always @(*) begin
        n_state = state;
        case (state)
            // rx가 0으로 떨어졌을 때,
            IDLE: if (!sync_ff2) n_state = START;
            START: begin
                // rx_baud_tick이 들어오면서 rx_baud_tick_cnt가 7 일때
                if (rx_baud_tick && baud_tick_cnt_reg == 7) begin
                    // rx가 그래도 0으로 떨어져있을 때,
                    if (!sync_ff2) n_state = DATA;
                    else n_state = IDLE;
                end
            end
            DATA: begin
                if (rx_baud_tick && baud_tick_cnt_reg == 15) begin
                    if (bit_cnt_reg == 7) n_state = STOP;
                    else n_state = DATA;
                end
            end
            STOP: begin
                if (rx_baud_tick && baud_tick_cnt_reg == 15) begin
                    n_state = IDLE;
                end
            end
        endcase
    end

    // 3. baud tick cnt
    always @(*) begin
        baud_tick_cnt_next = baud_tick_cnt_reg;
        case (state)
            IDLE: baud_tick_cnt_next = 0;
            START: begin
                if (rx_baud_tick) begin
                    if (baud_tick_cnt_reg == 7) baud_tick_cnt_next = 0;
                    else baud_tick_cnt_next = baud_tick_cnt_reg + 1;
                end
            end
            DATA: begin
                if (rx_baud_tick) begin
                    if (baud_tick_cnt_reg == 15) baud_tick_cnt_next = 0;
                    else baud_tick_cnt_next = baud_tick_cnt_reg + 1;
                end
            end
            STOP: begin
                if (rx_baud_tick) begin
                    if (baud_tick_cnt_reg == 15) baud_tick_cnt_next = 0;
                    else baud_tick_cnt_next = baud_tick_cnt_reg + 1;
                end
            end
            default: baud_tick_cnt_next = 0;
        endcase
    end

    // 4. bit cnt
    always @(*) begin
        bit_cnt_next = bit_cnt_reg;
        case (state)
            IDLE: bit_cnt_next = 0;
            START: bit_cnt_next = 0;
            DATA: begin
                if (rx_baud_tick && baud_tick_cnt_reg == 15) begin
                    if (bit_cnt_reg == 7) bit_cnt_next = 0;
                    else bit_cnt_next = bit_cnt_reg + 1;
                end
            end
            STOP: bit_cnt_next = 0;
            default: bit_cnt_next = 0;
        endcase
    end

    // 5. output combinational logic
    assign rx_data = rx_data_reg;

    always @(*) begin
        rx_data_next = rx_data_reg;
        case (state)
            IDLE: rx_data_next = rx_data_reg;
            START: begin
                if (rx_baud_tick && baud_tick_cnt_reg == 7 && !sync_ff2)
                    rx_data_next = 0;
            end
            DATA: begin
                // rx_baud_tick이 들어오면서 cnt가 15인 시점에서
                if (rx_baud_tick && baud_tick_cnt_reg == 15) begin
                    // LSB
                    rx_data_next = {sync_ff2, rx_data_reg[7:1]};
                end
            end
            STOP: rx_data_next = rx_data_reg;
            default: rx_data_next = rx_data_reg;
        endcase
    end

    // 6. done
    assign rx_done = rx_done_reg;

    always @(*) begin
        rx_done_next = rx_done_reg;
        case (state)
            IDLE: rx_done_next = 0;
            START: rx_done_next = 0;
            DATA: rx_done_next = 0;
            STOP: begin
                if (rx_baud_tick && baud_tick_cnt_reg == 15 && sync_ff2)
                    rx_done_next = 1;
                else rx_done_next = 0;
            end
            default: rx_done_next = 0;
        endcase
    end

    // 7. rx_frame_error
    assign rx_frame_error = rx_frame_error_reg;

    always @(*) begin
        rx_frame_error_next = rx_frame_error_reg;
        case (state)
            IDLE: rx_frame_error_next = 0;
            START: rx_frame_error_next = 0;
            DATA: rx_frame_error_next = 0;
            STOP: begin
                if (rx_baud_tick && baud_tick_cnt_reg == 15 && !sync_ff2)
                    rx_frame_error_next = 1;
                else rx_frame_error_next = 0;
            end
            default: rx_frame_error_next = 0;
        endcase
    end

endmodule
