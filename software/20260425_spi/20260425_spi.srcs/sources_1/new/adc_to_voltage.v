`timescale 1ns / 1ps

module adc_to_voltage (
    input  [7:0] adc_data,
    output [11:0] voltage_mv
);

assign voltage_mv = adc_data * 3300 / 255;

endmodule