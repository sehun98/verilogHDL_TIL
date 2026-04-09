`timescale 1ns / 1ps

module tb_FND_Controller;
    reg clk;
    reg rst_n;
    // wire [13:0] data,
    wire [3:0] digit;
    wire [7:0] seg;
    
    initial begin
        {clk, rst_n} = 2'b00;
        #10 rst_n = 1;
    end

    always #5 clk = ~clk;

    FND_Controller u1_FND_Controller (
        .clk  (clk),
        .rst_n(rst_n),
        //data(data),
        .digit(digit),
        .seg  (seg)
    );

endmodule
