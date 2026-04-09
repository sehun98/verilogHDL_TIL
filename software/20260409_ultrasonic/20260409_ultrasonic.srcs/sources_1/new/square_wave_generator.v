`timescale 1ns / 1ps

module square_wave_generator(
    input  wire clk,
    input  wire rst_n,
    output reg  square_wave_1ms_toggle
);
    reg [15:0] count;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= 0;
            square_wave_1ms_toggle <= 0;
        end else begin
            if (count == 50_000-1) begin
                count <= 0;
                square_wave_1ms_toggle <= ~square_wave_1ms_toggle;
            end else begin
                count <= count + 1;
            end
        end
    end

endmodule