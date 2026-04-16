`timescale 1ns / 1ps

module n_modulo_counter #(
    parameter N = 60,
    parameter TIMES = 100,
    parameter BIT_WIDTH = 7
) (
    input wire clk,
    input wire rst_n,
    input wire en,
    output reg [6:0] count,
    output reg tick,

    input  wire                 i_tick,
    output reg  [BIT_WIDTH-1:0] time_counter,
    output reg                  o_tick
);
    localparam WIDTH = $clog2(N);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= 0;
            tick  <= 0;
        end else begin
            tick <= 0;  // en 내부로 들어가면 안됨
            if (en) begin
                if (count == N - 1) begin
                    count <= 0;
                    tick  <= 1;
                end else begin
                    count <= count + 1;
                end
            end
        end
    end



    reg [BIT_WIDTH-1:0] counter_reg, counter_next;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter_reg <= 0;
        end else begin
            counter_reg <= counter_next;
        end
    end

    always @(*) begin
        counter_next = counter_reg;
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
