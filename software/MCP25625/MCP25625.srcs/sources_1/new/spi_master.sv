`timescale 1ns / 1ps

// mode 0 0
module spi_master (
    input logic clk,
    input logic rst_n,

    input  logic [7:0] tx_data,
    output logic [7:0] rx_data,

    input  logic request,
    output logic done,
    input  logic sck,

    output logic SCK,
    output logic MOSI,
    input  logic MISO
);
    typedef enum logic [2:0] {
        IDLE,
        LOAD,
        TRANSFER,
        LAST_FALL,
        DONE
    } state_t;

    state_t state, n_state;

    logic pre_sck;
    logic sck_rising_tick, sck_falling_tick;

    assign sck_rising_tick  = sck & ~pre_sck;
    assign sck_falling_tick = ~sck & pre_sck;

    logic sck_en_reg;
    logic sck_en_next;

    assign SCK = sck_en_reg & sck;

    logic done_reg, done_next;

    assign done = done_reg;

    logic [7:0] tx_buff_next, tx_buff_reg;
    logic [7:0] rx_buff_next, rx_buff_reg;

    assign rx_data = rx_buff_reg;

    logic [2:0] bit_cnt_reg, bit_cnt_next;

    logic MOSI_reg, MOSI_next;

    assign MOSI = MOSI_reg;

    // state register
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            pre_sck <= 1'b0;
            sck_en_reg <= 1'b0;
            done_reg <= 1'b0;
            tx_buff_reg <= 8'b0;
            rx_buff_reg <= 8'b0;
            bit_cnt_reg <= 3'b0;
            MOSI_reg <= 1'b0;
        end else begin
            state <= n_state;
            pre_sck <= sck;
            sck_en_reg <= sck_en_next;
            done_reg <= done_next;
            tx_buff_reg <= tx_buff_next;
            rx_buff_reg <= rx_buff_next;
            bit_cnt_reg <= bit_cnt_next;
            MOSI_reg <= MOSI_next;
        end
    end

    // 2. next state combinational logic
    always_comb begin
        n_state = state;
        sck_en_next = sck_en_reg;
        done_next = done_reg;
        tx_buff_next = tx_buff_reg;
        rx_buff_next = rx_buff_reg;
        bit_cnt_next = bit_cnt_reg;
        MOSI_next = MOSI_reg;
        case (state)
            IDLE: begin
                sck_en_next = 1'b0;
                done_next = 1'b0;
                bit_cnt_next = 3'd0;
                rx_buff_next = 8'd0;
                if (request) begin
                    //tx_buff_next = tx_data;
                    MOSI_next = tx_data[7];
                    tx_buff_next = {tx_data[6:0], 1'b0};
                    n_state = LOAD;
                end
            end
            LOAD: begin
                if (sck_falling_tick) begin
                    sck_en_next = 1'b1;
                    if (bit_cnt_reg != 3'd0) begin
                        MOSI_next    = tx_buff_reg[7];
                        tx_buff_next = {tx_buff_reg[6:0], 1'b0};
                    end
                    n_state = TRANSFER;
                end
            end
            TRANSFER: begin
                if (sck_rising_tick) begin
                    rx_buff_next = {rx_buff_reg[6:0], MISO};
                    if (bit_cnt_reg == 3'd7) begin
                        bit_cnt_next = 3'b0;
                        n_state = LAST_FALL;
                    end else begin
                        bit_cnt_next = bit_cnt_reg + 1'b1;
                        n_state = LOAD;
                    end
                end
            end
            LAST_FALL: begin
                if (sck_falling_tick) begin
                    sck_en_next = 1'b0;
                    n_state = DONE;
                end
            end
            DONE: begin
                done_next = 1;
                MOSI_next = 0;
                rx_buff_next = rx_buff_reg;
                n_state = IDLE;
            end
        endcase
    end

endmodule
