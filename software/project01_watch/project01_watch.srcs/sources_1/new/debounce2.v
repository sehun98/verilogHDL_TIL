`timescale 1ns / 1ps

module debounce2 (
    input  wire clk,
    input  wire rst_n,
    input  wire din,
    output wire dout
);
    // clock divider
    // 100MHz -> 100KHz

    parameter F_COUNT = 100_000_000 / 100_000;

    reg [$clog2(F_COUNT)-1:0] r_counter;
    reg clk_100khz;

    reg [7:0] sync_reg, sync_next;
    wire debounce;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            r_counter  <= 0;
            clk_100khz <= 1'b0;
        end else begin
            r_counter <= r_counter + 1;

            if (r_counter == F_COUNT - 1) begin
                r_counter  <= 0;
                clk_100khz <= 1'b1;
            end else begin
                clk_100khz <= 1'b0;
            end
        end
    end

    always @(posedge clk_100khz or negedge rst_n) begin
        if (!rst_n) begin
            sync_reg <= 1'b0;
        end else begin
            sync_reg <= sync_next;
        end
    end

    always @(*) begin
        sync_next = {din, sync_reg[7:1]};
        //sync_next = {sync_reg[6:0],din};
    end

    assign debounce = &sync_reg;

    // rising edge detect
    reg prev_data;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prev_data <= 0;
        end else begin
            prev_data <= debounce;
        end
    end

    assign dout = debounce & ~prev_data;

endmodule
