`timescale 1ns / 1ps

module tb_rising_edge_detector;
    reg  clk;
    reg  rst_n;
    reg  level_in;
    wire pulse_out;

    rising_edge_detector u1_rising_edge_detector (
        .clk(clk),
        .rst_n(rst_n),
        .level_in(level_in),
        .pulse_out(pulse_out)
    );

    initial begin
        {clk, rst_n, level_in} = 3'b000;
        repeat(5) @(posedge clk);
        rst_n = 1'b1;

        level_in = 1'b1;
        #10;
        level_in = 1'b0;
        
        
        #1000_000; // 1ms 
        level_in = 1'b1;
        #1000_000_00; // 100ms
        level_in = 1'b0;
        #1000_000_00; // 100ms

        $finish;
    end

    always #5 clk = ~clk;

endmodule
