`timescale 1ns / 1ps

module spi_slave (
    input logic clk,
    input logic reset,

    // internal
    input  logic [7:0] tx_data,
    output logic [7:0] rx_data,
    output logic       done,

    input logic cpol,
    input logic cpha,

    // external
    input  logic sclk,
    input  logic mosi,
    output logic miso,
    input  logic ss_n
);
    typedef enum logic [1:0] {
        IDLE = 2'b00,
        DATA,
        DONE
    } state_t;

    state_t state;

    logic [7:0] tx_shift_reg;
    logic [7:0] rx_shift_reg;
    logic [3:0] edge_cnt;
    logic sclk_prev;

    logic rising_edge;
    logic falling_edge;

    assign rising_edge  = sclk & ~sclk_prev;
    assign falling_edge = ~sclk & sclk_prev;

    logic sample_edge;
    logic shift_edge;

    assign sample_edge = (cpol ^ cpha) ? falling_edge : rising_edge;
    assign shift_edge  = (cpol ^ cpha) ? rising_edge : falling_edge;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            sclk_prev <= 1'b0;
        end else begin
            sclk_prev <= sclk;
        end
    end

    // SPI_CR
    // reserved[31:6] start[5] spi_br[4:2] cpol[1] cpha[0] 
    // SPI_SR
    // reserved[31:4] tx_busy[3] tx_overrun_error[2] rx_done[1] rx_frame_error[0]
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state        <= IDLE;
            miso         <= 1'b0;
            done         <= 1'b0;
            rx_data      <= 8'd0;
            tx_shift_reg <= 8'd0;
            rx_shift_reg <= 8'd0;
            edge_cnt     <= 4'd0;
        end else begin
            case (state)
                IDLE: begin
                    rx_data      <= rx_data;
                    miso         <= 1'b0;
                    done         <= 1'b0;
                    tx_shift_reg <= 8'd0;
                    edge_cnt     <= 4'd0;
                    if (ss_n == 1'b0) begin
                        //rx_data      <= 8'd0;
                        rx_shift_reg <= 8'd0;
                        done         <= 1'b0;
                        edge_cnt     <= 4'd0;
                        if (cpha == 1'b0) begin
                            // CPHA=0: 첫 bit는 첫 edge 전에 미리 출력
                            miso         <= tx_data[7];
                            tx_shift_reg <= {tx_data[6:0], 1'b0};
                        end else begin
                            // CPHA=1: 첫 edge에서 첫 bit 출력
                            miso         <= 1'b0;
                            tx_shift_reg <= tx_data;
                        end
                        state <= DATA;
                    end
                end
                DATA: begin
                    if (sample_edge) begin
                        rx_shift_reg <= {rx_shift_reg[6:0], mosi};

                        if ((cpha == 1'b0 && edge_cnt == 4'd14) ||
            (cpha == 1'b1 && edge_cnt == 4'd15)) begin
                            rx_data <= {rx_shift_reg[6:0], mosi};
                        end
                    end

                    if (shift_edge) begin
                        miso         <= tx_shift_reg[7];
                        tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
                    end

                    if (sample_edge || shift_edge) begin
                        if (edge_cnt == 4'd15) begin
                            state    <= DONE;
                            edge_cnt <= 4'd0;
                        end else begin
                            edge_cnt <= edge_cnt + 1'b1;
                        end
                    end
                end
                DONE: begin
                    done <= 1'b1;
                    edge_cnt <= 4'd0;
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule
