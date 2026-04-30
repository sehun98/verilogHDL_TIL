`timescale 1ns / 1ps

module tb_ultrasonic;

    reg clk;
    reg rst_n;
    reg request;
    wire trig;
    reg echo;
    wire [8:0] distance;

    ultrasonic u1_ultrasonic (
        .clk(clk),
        .rst_n(rst_n),
        .request(request),
        .trig(trig),
        .echo(echo),
        .distance(distance)
    );

    localparam US_DELAY = 1000; // 1us
    localparam MS_DELAY = 1000_000; // 1ms

    always #5 clk = ~clk;
    initial begin
        clk = 0;
        rst_n = 0;
        request = 0;
        echo = 0;
        repeat (5) @(posedge clk);
        rst_n = 1;

        @(posedge clk);
        request = 1;
        @(posedge clk);
        request = 0;

        @(negedge trig);
        #(US_DELAY * 20);

        echo = 1;
        #(MS_DELAY); // 1ms = 20000
        // 1000_000hz = 1us
        echo = 0;

        #(US_DELAY * 20);

        $finish;
    end


endmodule


