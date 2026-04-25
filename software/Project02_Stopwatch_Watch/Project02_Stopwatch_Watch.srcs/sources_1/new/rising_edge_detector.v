`timescale 1ns / 1ps

module rising_edge_detector(
    input  wire clk,
    input  wire rst_n,
    input  wire level_in,
    output reg  pulse_out
);

reg prev_data;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        prev_data <= 0;
        pulse_out <= 0;
    end else begin
        pulse_out <= level_in & ~prev_data; // rising edge detector
        // pulse_out <= level_in ^ prev_data; // both edge detector
        // pulse_out <= ~level_in & prev_data; // falling edge detector
        prev_data <= level_in;
    end
end

endmodule