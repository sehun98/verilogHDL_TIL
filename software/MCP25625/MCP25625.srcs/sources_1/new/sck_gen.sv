`timescale 1ns / 1ps

module sck_gen #(
    parameter CLOCK_FREQ_HZ = 100_000_000,
    parameter BAUD_RATE = 500_000
) (
    input  logic clk,
    input  logic rst_n,
    output logic sck
);
    localparam CNT = 100;  // CLOCK_FREQ_HZ / BAUD_RATE / 2;
    localparam CNT_WIDTH = $clog2(CNT);
    reg [CNT_WIDTH-1:0] count;

    always_ff @(posedge clk or negedge rst_n) begin : sck_gen
        if (!rst_n) begin
            sck   <= 1'b0;
            count <= {CNT_WIDTH{1'b0}};
        end else begin
            if (count == CNT - 1) begin
                count <= {CNT_WIDTH{1'b0}};
                sck   <= ~sck;
            end else begin
                count <= count + 1'b1;
            end
        end
    end
endmodule
