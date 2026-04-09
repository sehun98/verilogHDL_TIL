`timescale 1ns / 1ps

module top_ultrasonic (
    input wire clk,
    input wire rst_n,
    input wire echo,
    output wire [7:0] seg,
    output wire [3:0] digit,
    output wire trig
);
    wire [3:0] w_digit_out;
    wire [1:0] w_digit_sel;

    wire [9:0] w_distance;

    wire w_square_wave_1ms_toggle;

    wire [3:0] w_digit_ones;
    wire [3:0] w_digit_tens;
    wire [3:0] w_digit_hundreds;
    wire [3:0] w_digit_thousands;

    wire w_start;
    ultrasonic u1_ultrasonic (
        .clk(clk),
        .rst_n(rst_n),
        .start(w_start),
        .distance(w_distance),
        .trig(trig),
        .echo(echo)
    );

    start_gen_100ms #(
        .CLOCK_FREQ(100_000_000)
    ) u2_start_gen_100ms (
        .clk(clk),
        .rst_n(rst_n),
        .tick_10hz(w_start)
    );

    FND_Controller u3_FND_Controller(
        .clk(clk),
        .rst_n(rst_n),
        .data(w_distance),
        .digit(digit),
        .seg(seg)
    );

endmodule
