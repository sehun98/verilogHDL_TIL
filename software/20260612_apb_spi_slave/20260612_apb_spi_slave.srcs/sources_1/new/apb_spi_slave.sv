`timescale 1ns / 1ps

module apb_spi_slave (
    input logic PCLK,
    input logic PRESETn,

    input logic        PSEL,
    input logic        PENABLE,
    input logic        PWRITE,
    //input logic [ 3:0] PSTRB,
    input logic [31:0] PADDR,
    input logic [31:0] PWDATA,

    output logic [31:0] PRDATA,
    output logic        PREADY,
    output logic        PSLVERR,

    input  logic spi_sclk,
    input  logic spi_mosi,
    output logic spi_miso,
    input  logic spi_cs
);
    logic apb_setup;
    logic apb_access;
    logic apb_write;
    logic apb_read;

    assign apb_setup  = PSEL & !PENABLE;
    assign apb_access = PSEL & PENABLE;
    assign apb_read   = apb_access & !PWRITE;
    assign apb_write  = apb_access & PWRITE;

    // 0x00 SPI_CR 
    // 0x04 SPI_SR Status register
    // 0x08 SPI_DR
    logic [31:0] spi_cr;
    logic [31:0] spi_sr;
    logic [31:0] spi_tx_data;
    logic [31:0] spi_rx_data;

    spi_slave u1_spi_slave (
        .clk        (PCLK),
        .rst_n      (PRESETn),
        .SPI_CR     (spi_cr),
        .SPI_SR     (spi_sr),
        .SPI_TX_DATA(spi_tx_data),
        .SPI_RX_DATA(spi_rx_data),
        .spi_sclk   (spi_sclk),
        .spi_mosi   (spi_mosi),
        .spi_miso   (spi_miso),
        .spi_cs     (spi_cs)
    );
    // SPI_SR
    // reserved[31:4] tx_busy[3] tx_overrun_error[2] rx_done[1] rx_frame_error[0]
    logic tx_busy;
    logic tx_overrun_error;
    logic rx_done;
    logic rx_frame_error;

    assign tx_busy = spi_sr[3];
    assign tx_overrun_error = spi_sr[2];
    assign rx_done = spi_sr[1];
    assign rx_frame_error = spi_sr[0];

    always_ff @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            spi_cr <= 32'd0;
            spi_tx_data <= 32'd0;
        end else begin
            if (apb_write) begin
                case (PADDR[7:0])
                    8'h00: spi_cr <= PWDATA;
                    8'h08: if (!tx_busy) spi_tx_data <= PWDATA;
                endcase
            end
        end
    end

    assign PREADY  = 1'b1;
    assign PSLVERR = 1'b0;

    always_comb begin
        PRDATA = 32'd0;
        if (apb_read) begin
            case (PADDR[7:0])
                8'h00:   PRDATA = spi_cr;
                8'h04:   PRDATA = spi_sr;
                8'h08:   PRDATA = spi_rx_data;
                default: PRDATA = 32'd0;
            endcase
        end
    end
endmodule

module spi_slave (
    input logic clk,
    input logic rst_n,

    input  logic [31:0] SPI_CR,
    output logic [31:0] SPI_SR,
    input  logic [31:0] SPI_TX_DATA,
    output logic [31:0] SPI_RX_DATA,

    input  logic spi_sclk,
    input  logic spi_mosi,
    output logic spi_miso,
    input  logic spi_cs
);

    // SPI_CR
    // reserved[31:6] start[5] spi_br[4:2] cpol[1] cpha[0] 
    // SPI_SR
    // reserved[31:4] tx_busy[3] tx_overrun_error[2] rx_done[1] rx_frame_error[0]
    logic start;
    logic [2:0] spi_br;
    logic cpol;
    logic cpha;

    assign start  = SPI_CR[5];
    assign spi_br = SPI_CR[4:2];
    assign cpol   = SPI_CR[1];
    assign cpha   = SPI_CR[0];

    logic tx_busy;
    logic tx_overrun_error;
    logic rx_done;
    logic rx_frame_error;

    assign SPI_SR = {28'd0, tx_busy, tx_overrun_error, rx_done, rx_frame_error};

    typedef enum logic [1:0] {
        IDLE = 2'b00,
        DATA,
        DONE
    } state_t;

    state_t state;

    logic [7:0] tx_shift_reg;
    logic [3:0] edge_cnt;
    logic spi_sclk_prev;
logic tick;


assign tick = spi_sclk ^ spi_sclk_prev;

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        spi_sclk_prev <= 0;
    end else begin
        spi_sclk_prev <= spi_sclk;
    end
end

    // SPI_CR
    // reserved[31:6] start[5] spi_br[4:2] cpol[1] cpha[0] 
    // SPI_SR
    // reserved[31:4] tx_busy[3] tx_overrun_error[2] rx_done[1] rx_frame_error[0]
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state            <= IDLE;
            spi_miso         <= 1'b0;
            tx_busy          <= 1'b0;
            tx_overrun_error <= 1'b0;
            rx_done          <= 1'b0;
            rx_frame_error   <= 1'b0;
            SPI_RX_DATA      <= 32'd0;
            tx_shift_reg     <= 8'd0;
            edge_cnt         <= 4'd0;
        end else begin
            case (state)
                IDLE: begin
                    SPI_RX_DATA      <= SPI_RX_DATA;
                    spi_miso         <= 1'b0;
                    tx_busy          <= 1'b0;
                    tx_overrun_error <= 1'b0;
                    rx_done          <= rx_done;
                    rx_frame_error   <= 1'b0;
                    tx_shift_reg     <= 8'd0;
                    edge_cnt         <= 4'd0;
                    if (spi_cs == 1'b0) begin
                        tx_busy     <= 1'b1;
                        SPI_RX_DATA <= 32'd0;
                        rx_done <= 1'b0;
                        edge_cnt    <= 4'd0;
                        if (cpha == 1'b0) begin
                            // CPHA=0: 첫 bit는 첫 edge 전에 미리 출력
                            spi_miso     <= SPI_TX_DATA[7];
                            tx_shift_reg <= {SPI_TX_DATA[6:0], 1'b0};
                        end else begin
                            // CPHA=1: 첫 edge에서 첫 bit 출력
                            spi_miso     <= 1'b0;
                            tx_shift_reg <= SPI_TX_DATA[7:0];
                        end
                        state <= DATA;
                    end
                end
                DATA: begin
                    if (tick) begin
                        if ((cpha == 1'b0 && edge_cnt[0] == 1'b0) || (cpha == 1'b1 && edge_cnt[0] == 1'b1)) begin
                            // read
                            SPI_RX_DATA[7:0] <= {SPI_RX_DATA[6:0], spi_mosi};
                        end else begin
                            // write
                            spi_miso     <= tx_shift_reg[7];
                            tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
                        end
                        if (edge_cnt == 4'd15) begin
                            state <= DONE;
                        end else begin
                            edge_cnt <= edge_cnt + 1'b1;
                        end
                    end
                end
                DONE: begin
                    tx_busy <= 1'b0;
                    rx_done <= 1'b1;
                    edge_cnt <= 4'd0;
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule
