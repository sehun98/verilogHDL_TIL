`timescale 1ns / 1ps

module spi_master_core (
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
    // reserved[31:6] MSTR[6] start[5] spi_br[4:2] cpol[1] cpha[0] 
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

    logic sclk_enable;
    logic tick;

    logic [7:0] tx_shift_reg;

    spi_baudrate u1_spi_baudrate (
        .clk(clk),
        .rst_n(rst_n),
        .enable(sclk_enable),
        .SPI_BR(spi_br),
        .tick(tick)
    );
    logic [3:0] edge_cnt;


    assign tx_overrun_error = tx_busy && start;

    // SPI_CR
    // reserved[31:6] start[5] spi_br[4:2] cpol[1] cpha[0] 
    // SPI_SR
    // reserved[31:4] tx_busy[3] tx_overrun_error[2] rx_done[1] rx_frame_error[0]
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state          <= IDLE;
            sclk_enable    <= 1'b0;
            spi_cs         <= 1'b1;
            spi_mosi       <= 1'b0;
            tx_busy        <= 1'b0;
            rx_done        <= 1'b0;
            rx_frame_error <= 1'b0;
            SPI_RX_DATA    <= 32'd0;
            spi_sclk       <= cpol;
            tx_shift_reg   <= 8'd0;
            edge_cnt       <= 4'd0;
        end else begin
            case (state)
                IDLE: begin
                    SPI_RX_DATA    <= SPI_RX_DATA;
                    sclk_enable    <= 1'b0;
                    spi_cs         <= 1'b1;
                    spi_mosi       <= 1'b0;
                    tx_busy        <= 1'b0;
                    rx_done        <= rx_done;
                    rx_frame_error <= 1'b0;
                    spi_sclk       <= cpol;
                    tx_shift_reg   <= 8'd0;
                    edge_cnt       <= 4'd0;
                    if (start) begin
                        SPI_RX_DATA <= 32'd0;
                        sclk_enable <= 1'b1;
                        spi_cs      <= 1'b0;
                        tx_busy     <= 1'b1;
                        rx_done     <= 1'b0;
                        spi_sclk    <= cpol;
                        edge_cnt    <= 4'd0;
                        if (cpha == 1'b0) begin
                            // CPHA=0: 첫 bit는 첫 edge 전에 미리 출력
                            spi_mosi     <= SPI_TX_DATA[7];
                            tx_shift_reg <= {SPI_TX_DATA[6:0], 1'b0};
                        end else begin
                            // CPHA=1: 첫 edge에서 첫 bit 출력
                            spi_mosi     <= 1'bz;
                            tx_shift_reg <= SPI_TX_DATA[7:0];
                        end
                        state <= DATA;
                    end
                end
                DATA: begin
                    if (tick) begin
                        spi_sclk <= ~spi_sclk;
                        if ((cpha == 1'b0 && edge_cnt[0] == 1'b0) || (cpha == 1'b1 && edge_cnt[0] == 1'b1)) begin
                            // read
                            SPI_RX_DATA[7:0] <= {SPI_RX_DATA[6:0], spi_miso};
                        end else begin
                            // write
                            spi_mosi     <= tx_shift_reg[7];
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
                    sclk_enable <= 1'b0;
                    spi_cs      <= 1'b1;
                    tx_busy     <= 1'b0;
                    rx_done     <= 1'b1;
                    edge_cnt    <= 4'd0;
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
