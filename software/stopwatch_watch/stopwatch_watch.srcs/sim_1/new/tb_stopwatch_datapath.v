`timescale 1ns / 1ns

module tb_stopwatch_datapath;
    reg        clk;
    reg        rst_n;
    reg        run;
    reg        clear;
    reg        mode;
    wire [6:0] msec;
    wire [5:0] sec;
    wire [5:0] min;
    wire [4:0] hour;

    localparam DELAY_SET = 100_000_000;

    stopwatch_datapath u1_stopwatch_datapath (
        .clk  (clk),
        .rst_n(rst_n),
        .run  (run),
        .clear(clear),
        .mode (mode),
        .msec (msec),
        .sec  (sec),
        .min  (min),
        .hour (hour)
    );


    always #5 clk = ~clk;

    initial begin
        clk   = 0;
        rst_n = 0;
        run   = 0;
        clear = 0;
        mode  = 0;
        repeat (5) @(posedge clk);
        rst_n = 1;
        run   = 1;
        repeat (1) #(DELAY_SET);

        mode = 1;
        repeat (1) #(DELAY_SET);

        clear = 1;
        repeat (1) #(DELAY_SET);
        $finish;
    end

endmodule
