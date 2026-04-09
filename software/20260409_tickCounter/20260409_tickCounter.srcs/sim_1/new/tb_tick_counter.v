`timescale 1ns / 1ps

module tb_tick_counter;
    reg clk;
    reg rst_n;
    reg tick;
    wire [13:0] tick_count;

    // counter for tick generation
    reg [23:0] tick_gen_cnt;

    tick_counter #(
        .TICK_COUNT(10000)
    ) u1_tick_counter (
        .clk(clk),
        .rst_n(rst_n),
        .tick(tick),
        .tick_count(tick_count)
    );

    // 100MHz clock (10ns period)
    always #5 clk = ~clk;

    // tick generation (10Hz → 100ms period)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tick_gen_cnt <= 0;
            tick <= 0;
        end else begin
            if (tick_gen_cnt == 10_000_000 - 1) begin
                tick_gen_cnt <= 0;
                tick <= 1;   // 1-cycle pulse
            end else begin
                tick_gen_cnt <= tick_gen_cnt + 1;
                tick <= 0;
            end
        end
    end

    // reset
    initial begin
        {clk, rst_n, tick} = 3'b000;
        #10 rst_n = 1;
    end

    // simulation time
    initial begin
        #500_000_000; // 500ms
        $finish;
    end

endmodule