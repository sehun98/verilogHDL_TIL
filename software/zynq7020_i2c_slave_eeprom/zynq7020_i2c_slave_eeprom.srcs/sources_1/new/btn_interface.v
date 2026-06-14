`timescale 1ns / 1ps

module btn_interface #(
    parameter integer CLK_FREQ_HZ = 100_000_000,
    parameter integer DEBOUNCE_MS = 20
) (
    input  wire clk,
    input  wire rst_n,
    input  wire btn_in,
    output wire btn_pulse
);

    wire w_btn_debounced;

    debounce #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ),
        .DEBOUNCE_MS(DEBOUNCE_MS)
    ) u1_debounce (
        .clk  (clk),
        .rst_n(rst_n),
        .din  (btn_in),
        .dout (w_btn_debounced)
    );

    rising_edge_detector u2_rising_edge_detector (
        .clk(clk),
        .rst_n(rst_n),
        .level_in(w_btn_debounced),
        .pulse_out(btn_pulse)
    );
endmodule
