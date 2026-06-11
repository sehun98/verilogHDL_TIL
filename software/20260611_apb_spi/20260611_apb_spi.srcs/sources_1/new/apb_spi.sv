`timescale 1ns / 1ps

module apb_spi (
    input logic PCLK,
    input logic PRESETn,

    input logic PSEL,
    input logic PENABLE,
    input logic PWRITE,
    input logic [3:0] PSTRB,
    input logic [31:0] PWDATA,
    input logic [31:0] PADDR,

    output logic [31:0] PRDATA,
    output logic PREADY,
    output logic PSLVERR,

    output logic spi_sclk,
    output logic spi_mosi,
    input  logic spi_miso,
    output logic spi_cs
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

    spi_master u1_spi_master (
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

module spi_master (
    input logic clk,
    input logic rst_n,

    input  logic [31:0] SPI_CR,
    output logic [31:0] SPI_SR,
    input  logic [31:0] SPI_TX_DATA,
    output logic [31:0] SPI_RX_DATA,

    output logic spi_sclk,
    output logic spi_mosi,
    input  logic spi_miso,
    output logic spi_cs
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

    assign SPI_SR[3] = tx_busy;
    assign SPI_SR[2] = tx_overrun_error;
    assign SPI_SR[1] = rx_done;
    assign SPI_SR[0] = rx_frame_error;

    typedef enum logic [1:0] {
        IDLE = 2'b00,
        DATA,
        DONE
    } state_t;

    state_t state;

    logic sclk_enable;
    logic tick;

    logic [7:0] tx_shift_reg;
    logic [2:0] data_idx;

    logic step;

    spi_baudrate u1_spi_baudrate (
        .clk(clk),
        .rst_n(rst_n),
        .enable(sclk_enable),
        .SPI_BR(spi_br),
        .tick(tick)
    );

    // SPI_CR
    // reserved[31:6] start[5] spi_br[4:2] cpol[1] cpha[0] 
    // SPI_SR
    // reserved[31:4] tx_busy[3] tx_overrun_error[2] rx_done[1] rx_frame_error[0]
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            sclk_enable <= 1'b0;
            spi_cs <= 1'b1;
            spi_mosi <= 1'b0;
            tx_busy <= 1'b0;
            tx_overrun_error <= 1'b0;
            rx_done <= 1'b0;
            rx_frame_error <= 1'b0;
            SPI_RX_DATA <= 32'd0;
            step <= 1'd0;
            spi_sclk <= 1'd0;
        end else begin
            case (state)  // sclk_enable
                IDLE: begin
                    sclk_enable <= 1'b0;
                    spi_cs <= 1'b1;
                    spi_mosi <= 1'b0;
                    tx_busy <= 1'b0;
                    tx_overrun_error <= 1'b0;
                    rx_done <= 1'b0;
                    rx_frame_error <= 1'b0;
                    SPI_RX_DATA <= 32'd0;
                    data_idx <= 3'd0;
                    if (start) begin
                        sclk_enable <= 1'b1;
                        spi_cs      <= 1'b0;
                        tx_busy     <= 1'b1;
                        spi_sclk    <= cpol;
                        data_idx    <= 3'd0;

                        if (cpha == 1'b0) begin
                            spi_mosi     <= SPI_TX_DATA[7];
                            tx_shift_reg <= {SPI_TX_DATA[6:0], 1'b0};
                            step         <= 1'b0;  // read 먼저
                        end else begin
                            spi_mosi     <= 1'b0;
                            tx_shift_reg <= SPI_TX_DATA[7:0];
                            step         <= 1'b1;  // write 먼저
                        end

                        state <= DATA;
                    end
                end
                DATA: begin
                    if (tick) begin
                        spi_sclk <= ~spi_sclk;

                        if (step) begin  // write / shift
                            spi_mosi     <= tx_shift_reg[7];
                            tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
                            step         <= 1'b0;
                        end else begin  // read / sample
                            SPI_RX_DATA[7:0] <= {SPI_RX_DATA[6:0], spi_miso};

                            if (data_idx == 3'd7) begin
                                state <= DONE;
                            end else begin
                                data_idx <= data_idx + 1'b1;
                            end

                            step <= 1'b1;
                        end
                    end
                end
                DONE: begin
                    sclk_enable <= 1'b0;
                    spi_cs      <= 1'b1;
                    tx_busy     <= 1'b0;
                    rx_done     <= 1'b1;
                    data_idx    <= 3'd0;
                    spi_sclk    <= cpol;
                    state       <= IDLE;
                end
            endcase
        end
    end
endmodule

// SPI_CR[5:3]
// RP[2] RP[1] RP[0]
// 0 0 0 100_000_000 / 2 = 50_000_000
// 0 0 1 100_000_000 / 4 = 25_000_000
// 0 1 0 100_000_000 / 8 = 12_500_000
// 0 1 1 100_000_000 / 16 = 6_750_000
// 1 0 0 100_000_000 / 32 = 3_125_000
// 1 0 1 100_000_000 / 64 = 1_562_500
// 1 1 0 100_000_000 / 128 = 781_250
// 1 1 1 100_000_000 / 256 = 390_625
module spi_baudrate (
    input  logic       clk,
    input  logic       rst_n,
    input  logic       enable,
    input  logic [2:0] SPI_BR,
    output logic       tick
);
    localparam CLOCK_FREQ_HZ = 100_000_000;
    logic [31:0] cnt;
    logic [31:0] half_count;
    always_comb begin
        case (SPI_BR)
            3'b000:  half_count = 32'd1;  // /2
            3'b001:  half_count = 32'd2;  // /4
            3'b010:  half_count = 32'd4;  // /8
            3'b011:  half_count = 32'd8;  // /16
            3'b100:  half_count = 32'd16;  // /32
            3'b101:  half_count = 32'd32;  // /64
            3'b110:  half_count = 32'd64;  // /128
            3'b111:  half_count = 32'd128;  // /256
            default: half_count = 32'd1;
        endcase
    end
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt  <= 32'd0;
            tick <= 1'b0;
        end else begin
            tick <= 1'b0;
            if (enable) begin
                if (cnt == half_count - 1) begin
                    cnt  <= 32'd0;
                    tick <= 1'b1;
                end else begin
                    cnt <= cnt + 1'b1;
                end
            end else begin
                cnt <= 32'd0;
            end
        end
    end
endmodule
