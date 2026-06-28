`timescale 1ns / 1ps

module gpio_core (
    input logic [7:0] GPIO_CR,
    output logic [7:0] GPIO_IDR,
    input   logic [7:0] GPIO_ODR,

    inout wire [7:0] gpio
);

    genvar i;

    generate
        for (i = 0; i < 8; i = i + 1) begin
            assign gpio[i] = GPIO_CR[i] ? GPIO_ODR[i] : 1'bz;
            assign GPIO_IDR[i] = GPIO_CR[i] ? 1'bz : gpio[i];
        end
    endgenerate
endmodule
