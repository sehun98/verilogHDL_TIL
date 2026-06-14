`timescale 1ns / 1ps

module control_board (
    input logic clk,
    input logic rst_n,

    // SW port
    input logic spi_i2c_mode,

    // BTN port
    input logic light_btn,
    input logic temp_btn,

    // FND port
    output logic [3:0] digit,
    output logic [7:0] seg,

    // SPI port
    output logic spi_sclk,
    output logic spi_mosi,
    input  logic spi_miso,
    output logic spi_cs,

    //I2C port
    output logic i2c_sck,
    inout  wire  i2c_sda
);


endmodule

module control_unit (
    input logic clk,
    input logic rst_n,

    // SW port
    input logic spi_i2c_mode,

    // BTN port
    input logic light_btn,
    input logic temp_btn,

    // FND port
    output logic [13:0] fnd_data,

    // SPI port
    output logic spi_start,
    output logic spi_cpol,
    output logic spi_cpha,
    output logic [2:0] spi_clk_div,
    input logic spi_busy,
    input logic spi_done,
    output logic [7:0] spi_tx_data,
    input logic [7:0] spi_rx_data

    //I2C port


);
    typedef enum logic {
        IDLE,
        REQ_TEMP,
        REQ_LIGHT,
        WAIT,
        DONE
    } state_t;

    state_t state;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            // FND setting
            fnd_data <= 14'd0;

            // SPI setting
            spi_start <= 1'd0;
            spi_cpol <= 1'd0;
            spi_cpha <= 1'd0;
            spi_clk_div <= 3'b000;  // 100_000_000 / 2
            spi_tx_data <= 8'd0;

            // I2C setting
        end else begin
            case (state)
                IDLE: begin

                    if (temp_btn) begin
                        state <= REQ_TEMP;
                    end else if (light_btn) begin
                        state <= REQ_LIGHT;
                    end
                end
                REQ_TEMP: begin
                    if (spi_i2c_mode) begin
                        // i2c_mode
                        // cmd_start <= 1'b1;
                    end else begin
                        // spi_mode
                        spi_start <= 1'b1;
                    end
                    state <= WAIT;
                end
                REQ_LIGHT: begin

                end
                WAIT: begin

                end
                DONE: begin

                end
            endcase
        end
    end

endmodule
