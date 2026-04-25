`timescale 1ns / 1ps

module adc081s02 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        request,
    output wire [11:0] voltage_mv,
    output wire        adc_busy,
    output wire        CS,
    output wire        MISO,
    output wire        SCLK
);
    wire w_sclk_square;
    wire [7:0] adc_data;

    spi_adc081s02 u1_spi_adc081s02 (
        .clk        (clk),
        .rst_n      (rst_n),
        .sclk_square(w_sclk_square),
        .request    (request),
        .adc_data   (adc_data),
        .adc_busy   (adc_busy),
        .CS         (CS),
        .MISO       (MISO),
        .SCLK       (SCLK)
    );

    sclk_gen #(
        .CLOCK_FREQ_HZ(100_000_000),
        .DIV_HALF     (32)
    ) u2_sclk_gen (
        .clk        (clk),
        .rst_n      (rst_n),
        .sclk_square(w_sclk_square)
    );

    adc_to_voltage u3_adc_to_voltage (
        .adc_data  (adc_data),
        .voltage_mv(voltage_mv)
    );

endmodule
