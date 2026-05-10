`timescale 1ns / 1ps

module tb_mcp25625_loopback;

    logic clk;
    logic rst_n;

    logic INT;
    logic CS;
    logic SCK;
    logic MOSI;
    logic MISO;

    // =========================================================
    // DUT
    // =========================================================
    mcp25625_loopback dut (
        .clk  (clk),
        .rst_n(rst_n),

        .INT  (INT),
        .CS   (CS),
        .SCK  (SCK),
        .MOSI (MOSI),
        .MISO (MISO)
    );

    // =========================================================
    // Clock
    // =========================================================
    initial clk = 0;
    always #5 clk = ~clk; // 100MHz

    // =========================================================
    // Fake MCP25625 SPI response
    // =========================================================

    logic [7:0] spi_shift_reg;
    logic [7:0] current_cmd;
    logic [7:0] current_addr;

    integer bit_cnt;
    integer byte_cnt;

    logic [7:0] tx_byte;

    // MISO output shift
    always_ff @(negedge SCK or posedge CS) begin
        if (CS) begin
            MISO <= 1'b0;
        end else begin
            MISO <= tx_byte[7];
            tx_byte <= {tx_byte[6:0], 1'b0};
        end
    end

    // MOSI capture
    always_ff @(posedge SCK or posedge CS) begin
        if (CS) begin
            spi_shift_reg <= 8'h00;
            current_cmd   <= 8'h00;
            current_addr  <= 8'h00;

            bit_cnt  <= 0;
            byte_cnt <= 0;

            tx_byte <= 8'h00;
        end else begin
            spi_shift_reg <= {spi_shift_reg[6:0], MOSI};

            bit_cnt <= bit_cnt + 1;

            if (bit_cnt == 7) begin

                // received byte
                case (byte_cnt)

                    // -------------------------------------------------
                    // Command byte
                    // -------------------------------------------------
                    0: begin
                        current_cmd <= {spi_shift_reg[6:0], MOSI};

                        // READ STATUS
                        if ({spi_shift_reg[6:0], MOSI} == 8'hA0) begin
                            tx_byte <= 8'b0000_1001;
                            // bit0 RX0IF
                            // bit3 TX0IF
                        end
                    end

                    // -------------------------------------------------
                    // Address byte
                    // -------------------------------------------------
                    1: begin
                        current_addr <= {spi_shift_reg[6:0], MOSI};

                        // READ RXB0 START
                        if (current_cmd == 8'h03 &&
                            {spi_shift_reg[6:0], MOSI} == 8'h61) begin

                            tx_byte <= 8'h24; // SIDH
                        end
                    end

                    // -------------------------------------------------
                    // RX frame data
                    // -------------------------------------------------
                    default: begin
                        if (current_cmd == 8'h03) begin
                            case (byte_cnt)

                                2:  tx_byte <= 8'h24; // SIDH
                                3:  tx_byte <= 8'h60; // SIDL
                                4:  tx_byte <= 8'h00; // EID8
                                5:  tx_byte <= 8'h00; // EID0
                                6:  tx_byte <= 8'h08; // DLC

                                7:  tx_byte <= 8'h11;
                                8:  tx_byte <= 8'h22;
                                9:  tx_byte <= 8'h33;
                                10: tx_byte <= 8'h44;
                                11: tx_byte <= 8'h55;
                                12: tx_byte <= 8'h66;
                                13: tx_byte <= 8'h77;
                                14: tx_byte <= 8'h88;

                                default:
                                    tx_byte <= 8'h00;
                            endcase
                        end
                    end
                endcase

                byte_cnt <= byte_cnt + 1;
                bit_cnt  <= 0;
            end
        end
    end

    // =========================================================
    // Stimulus
    // =========================================================
    initial begin

        rst_n = 0;
        INT   = 1;

        #100;
        rst_n = 1;

        // initialization 대기
        #100000;

        // RX interrupt 발생
        INT = 0;

        #50000;

        // interrupt clear 후 복귀
        INT = 1;

        #100000;

        $finish;
    end

endmodule