`timescale 1ns / 1ps

module tb_line_collector;
    parameter LINE_MAX = 64;

    reg                           clk;
    reg                           rst_n;

    wire                          fifo_r_en;
    reg  [                   7:0] fifo_data;
    reg                           fifo_empty;

    wire [        8*LINE_MAX-1:0] line_data;
    wire [$clog2(LINE_MAX+1)-1:0] line_length;
    wire                          line_valid;
    reg                           ready;

    line_collector #(
        .LINE_MAX(64)
    ) u1_line_collector (
        .clk(clk),
        .rst_n(rst_n),
        .fifo_r_en(fifo_r_en),
        .fifo_data(fifo_data),
        .fifo_empty(fifo_empty),
        .line_data(line_data),
        .line_length(line_length),
        .line_valid(line_valid),
        .ready(ready)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst_n = 0;
        fifo_data = 0;
        fifo_empty = 1;

        repeat(5) @(posedge clk);
        rst_n = 1;

        @(negedge clk);
        fifo_data = 8'h4C; // L
        fifo_empty = 0;
        ready = 1;

        @(negedge clk);
        fifo_data = 8'h45; // E
        fifo_empty = 0;
        ready = 1;

        @(negedge clk);
        fifo_data = 8'h44; // D
        fifo_empty = 0;
        ready = 1;

        @(negedge clk);
        fifo_data = 8'h20; // SP
        fifo_empty = 0;
        ready = 1;

        @(negedge clk);
        fifo_data = 8'h4F; // O 
        fifo_empty = 0;
        ready = 1;

        @(negedge clk);
        fifo_data = 8'h4E; // N
        fifo_empty = 0;

        @(negedge clk);
        fifo_data = 8'h0A; // \n
        fifo_empty = 0;
    end

endmodule
