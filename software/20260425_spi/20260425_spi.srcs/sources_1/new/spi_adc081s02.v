`timescale 1ns / 1ps

module spi_adc081s02 (
    input wire clk,
    input wire rst_n,

    input wire sclk_square,
    input wire request,
    output wire [7:0] adc_data,
    output wire adc_busy,

    output wire CS,
    input  wire MISO,
    output wire SCLK
);
    // IDLE
    // CS_LOW
    // DATA
    // CS_HIGH
    // WAIT

    localparam IDLE = 3'b000;
    localparam CS_LOW = 3'b001;
    localparam DATA = 3'b010;
    localparam CS_HIGH = 3'b011;
    localparam WAIT = 3'b100;

    // 0~7
    reg [2:0] state, n_state;

    // 0~15
    reg [3:0] bit_cnt_reg, bit_cnt_next;
    // 0~64
    reg [5:0] wait_cnt_reg, wait_cnt_next;

    reg sclk_en_reg, sclk_en_next;

    reg [15:0] adc_data_padding_reg, adc_data_padding_next;

    // 1. state & bit cnt register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            bit_cnt_reg <= 0;
            wait_cnt_reg <= 0;
            sclk_en_reg <= 0;
            adc_data_padding_reg <= 0;
        end else begin
            state <= n_state;
            bit_cnt_reg <= bit_cnt_next;
            wait_cnt_reg <= wait_cnt_next;
            sclk_en_reg <= sclk_en_next;
            adc_data_padding_reg <= adc_data_padding_next;
        end
    end

    reg  prev_sclk_square;
    wire sclk_rising_edge;

    // 2.0 sclk rising edge detect
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prev_sclk_square <= 0;
        end else begin
            prev_sclk_square <= sclk_square;
        end
    end

    assign sclk_rising_edge = sclk_square & ~prev_sclk_square;

    // 2. next state combinational logic
    always @(*) begin
        n_state = state;
        case (state)
            IDLE: if (request) n_state = CS_LOW;
            CS_LOW: begin
                if (sclk_square == 1'b1) n_state = DATA;
            end
            DATA:
            if (sclk_rising_edge) begin
                if (bit_cnt_reg == 15) begin
                    n_state = CS_HIGH;
                end
            end
            CS_HIGH: n_state = WAIT;
            WAIT:
            if (wait_cnt_reg == 34) begin
                n_state = IDLE;
            end
            default: n_state = state;
        endcase
    end

    // 3. bit_cnt_next combinational logic
    always @(*) begin
        bit_cnt_next = bit_cnt_reg;
        case (state)
            DATA:
            if (sclk_rising_edge) begin
                if (bit_cnt_reg == 15) begin
                    bit_cnt_next = 0;
                end else begin
                    bit_cnt_next = bit_cnt_reg + 1;
                end
            end
            default: bit_cnt_next = bit_cnt_reg;
        endcase
    end

    // 4. wait_cnt_next combinational logic
    always @(*) begin
        wait_cnt_next = wait_cnt_reg;
        case (state)
            WAIT:
            if (wait_cnt_reg == 34) begin
                wait_cnt_next = 0;
            end else begin
                wait_cnt_next = wait_cnt_reg + 1;
            end
            default: wait_cnt_next = wait_cnt_reg;
        endcase
    end

    assign SCLK = (sclk_en_reg) ? sclk_square : 1'b1;

    // 5. sclk_en_next combinational logic
    always @(*) begin
        sclk_en_next = sclk_en_reg;
        case (state)
            IDLE:    sclk_en_next = 0;
            CS_LOW:  sclk_en_next = 0;
            DATA:    sclk_en_next = 1;
            CS_HIGH: sclk_en_next = 0;
            WAIT:    sclk_en_next = 0;
            default: sclk_en_next = 0;
        endcase
    end

    // 6. adc_busy
    assign adc_busy = (state != IDLE);

    // 12 11 10 9 8 7 6 5
    // 15 14 13 12 ~ 5 4 3 2 1 0
    assign adc_data = adc_data_padding_reg[12:5];

    // 7. input MISO
    always @(*) begin
        adc_data_padding_next = adc_data_padding_reg;
        case (state)
            DATA:
            if (sclk_rising_edge) begin
                adc_data_padding_next = {adc_data_padding_reg[14:0], MISO};
            end
            default: adc_data_padding_next = adc_data_padding_reg;
        endcase
    end

    // 8. CS
    assign CS = (state == CS_LOW || state == DATA) ? 1'b0 : 1'b1;

endmodule
