`timescale 1ns / 1ps

module top_spi (
    input wire clk,
    input wire rst_n,
    output wire [3:0] digit,
    output wire [7:0] seg,
    input wire btn,
    output wire CS,
    input wire MISO,
    output wire SCLK
);
    wire [11:0] w_voltage_mv;
    wire request;

    FND_Controller u1_FND_Controller (
        .clk  (clk),
        .rst_n(rst_n),
        .data (w_voltage_mv),
        .digit(digit),
        .seg  (seg)
    );

    adc081s02 u2_adc081s02 (
        .clk(clk),
        .rst_n(rst_n),
        .request(request),
        .voltage_mv(w_voltage_mv),
        .adc_busy(),
        .CS(CS),
        .MISO(MISO),
        .SCLK(SCLK)
    );

    btn_interface u3_btn_interface (
        .clk(clk),
        .rst_n(rst_n),
        .btn_in(btn),
        .btn_pulse(request)
    );
endmodule
