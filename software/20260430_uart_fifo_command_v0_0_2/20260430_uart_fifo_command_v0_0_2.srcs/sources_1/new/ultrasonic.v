`timescale 1ns / 1ps

module ultrasonic (
    input wire clk,
    input wire rst_n,

    input wire ultrasonic_start,
    output wire ultrasonic_done,

    output wire [8:0] distance,
    output wire trig,
    input wire echo
);
endmodule

module ultrasonic_tick_gen (
    input  wire clk,
    input  wire rst_n,
    output reg  tick
);

endmodule

module ultrasonic_controller (
    input wire clk,
    input wire rst_n,
    input wire tick,

    input wire ultrasonic_start,
    output wire ultrasonic_done,

    output wire trig,
    input wire echo,
    // 0~400
    output wire [8:0] distance
);

endmodule