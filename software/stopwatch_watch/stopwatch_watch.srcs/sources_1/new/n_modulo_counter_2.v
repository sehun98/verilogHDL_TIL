`timescale 1ns / 1ps

module n_modulo_counter_2 #(
    parameter TIMES = 100,
    parameter BIT_WIDTH = 7
) (
    input  wire                 clk,
    input  wire                 rst_n,
    input  wire                 i_tick,
    input  wire                 clear,
    output wire  [BIT_WIDTH-1:0] time_counter,
    output reg                  o_tick
);
    reg [BIT_WIDTH-1:0] counter_reg, counter_next;

    assign time_counter = counter_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n || clear) begin
            counter_reg <= 0;
        end else begin
            counter_reg <= counter_next;
        end
    end

    always @(*) begin
        counter_next = counter_reg;
        o_tick = 0;
        if (i_tick) begin
            // output : counter_next, input : counter_reg
            counter_next = counter_reg + 1;
            if (counter_reg == TIMES - 1) begin
                counter_next = 0;
                o_tick = 1;
            end else begin
                o_tick = 0;
            end
        end
    end

endmodule
