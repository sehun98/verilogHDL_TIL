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

    typedef enum logic [1:0] {
        IDLE, START, DATA, STOP
    }state_t;

    state_t state, next_state;

    localparam STOP_RATE = 15;

    reg sync_ff1, sync_ff2;

    reg [3:0] baud_cnt_reg, baud_cnt_next;
    reg [2:0] bit_cnt_reg, bit_cnt_next;
    reg [7:0] rx_data_reg, rx_data_next;

    reg rx_done_reg, rx_done_next;
    reg rx_frame_error_reg, rx_frame_error_next;

    //==================================================
    // 0. RX Synchronizer
    //==================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_ff1 <= 1'b1;
            sync_ff2 <= 1'b1;
        end else begin
            sync_ff1 <= rx;
            sync_ff2 <= sync_ff1;
        end
    end

    //==================================================
    // 1. Sequential Logic
    //==================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state              <= IDLE;
            baud_cnt_reg       <= 0;
            bit_cnt_reg        <= 0;
            rx_data_reg        <= 0;
            rx_done_reg        <= 0;
            rx_frame_error_reg <= 0;
        end else begin
            state              <= next_state;
            baud_cnt_reg       <= baud_cnt_next;
            bit_cnt_reg        <= bit_cnt_next;
            rx_data_reg        <= rx_data_next;
            rx_done_reg        <= rx_done_next;
            rx_frame_error_reg <= rx_frame_error_next;
        end
    end

    //==================================================
    // 2. Combinational Logic
    //==================================================
    always @(*) begin
        next_state          = state;
        baud_cnt_next       = baud_cnt_reg;
        bit_cnt_next        = bit_cnt_reg;
        rx_data_next        = rx_data_reg;
        rx_done_next        = 1'b0;
        rx_frame_error_next = 1'b0;
        case (state)
            IDLE: begin
                baud_cnt_next = 0;
                bit_cnt_next  = 0;
                if (!sync_ff2) begin
                    next_state = START;
                end
            end
            START: begin
                bit_cnt_next = 0;
                if (rx_baud_tick) begin
                    if (baud_cnt_reg == 7) begin
                        baud_cnt_next = 0;
                        if (!sync_ff2) begin
                            rx_data_next = 0;
                            next_state   = DATA;
                        end else begin
                            next_state = IDLE;
                        end
                    end else begin
                        baud_cnt_next = baud_cnt_reg + 1;
                    end
                end
            end
            DATA: begin
                if (rx_baud_tick) begin
                    if (baud_cnt_reg == 15) begin
                        baud_cnt_next = 0;
                        rx_data_next = {sync_ff2, rx_data_reg[7:1]};
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
                bit_cnt_next = 0;
                if (rx_baud_tick) begin
                    if (baud_cnt_reg == STOP_RATE) begin
                        baud_cnt_next = 0;
                        next_state    = IDLE;
                        if (sync_ff2) begin
                            rx_done_next = 1'b1;
                        end else begin
                            rx_frame_error_next = 1'b1;
                        end
                    end else begin
                        baud_cnt_next = baud_cnt_reg + 1;
                    end
                end
            end
            default: begin
                next_state = IDLE;
            end
        endcase
    end

    //==================================================
    // Output
    //==================================================
    assign rx_data        = rx_data_reg;
    assign rx_done        = rx_done_reg;
    assign rx_frame_error = rx_frame_error_reg;

endmodule