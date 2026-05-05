`timescale 1ns / 1ps

module tb_FND_controller;
    reg clk;
    reg rst_n;
    reg [13:0] data;
    wire [3:0] digit;
    wire [7:0] fnd_decode;

    FND_controller u1_FND_controller (
        .clk(clk),
        .rst_n(rst_n),
        .data(data),
        .digit(digit),
        .fnd_decode(fnd_decode)
    );

    integer i;

    always #5 clk = ~clk;

    initial begin
        clk   = 0;
        rst_n = 0;
        repeat (5) @(posedge clk);
        rst_n = 1;

        #1000;

        for (i = 0; i < 10000; i = i + 1) begin
            data = i;
            #(100_000_000 / 1000);
        end

        #1000;
        $finish;
    end

endmodule
