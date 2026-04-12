`timescale 1ns / 1ps

module tb_fifo;
    reg clk;
    reg rst_n;

    reg [7:0] din;
    reg       w_en;
    wire [7:0] dout;
    reg       r_en;

    wire empty;
    wire full;

    fifo u1_fifo (
        .clk(clk),
        .rst_n(rst_n),
        .din(din),
        .w_en(w_en),
        .dout(dout),
        .r_en(r_en),
        .empty(empty),
        .full(full)
    );

    always #5 clk = ~clk;

    initial begin
        clk   = 0;
        rst_n = 0;
        din   = 0;
        w_en  = 0;
        r_en  = 0;

        repeat(5) @(posedge clk);
        rst_n = 1;

        repeat(2) @(posedge clk);

        // empty에서 read
        r_en = 1;
        @(posedge clk);
        r_en = 0;

        repeat(2) @(posedge clk);

        // write 1
        din = 8'd255;
        w_en = 1;
        @(posedge clk);
        w_en = 0;

        repeat(2) @(posedge clk);

        // write 2
        din = 8'd254;
        w_en = 1;
        @(posedge clk);
        w_en = 0;

        repeat(2) @(posedge clk);

        // read 1
        r_en = 1;
        @(posedge clk);
        r_en = 0;

        repeat(2) @(posedge clk);

        $finish;
    end

    initial begin
        $monitor("t=%0t rst_n=%b w_en=%b r_en=%b din=%d dout=%d empty=%b full=%b",
                  $time, rst_n, w_en, r_en, din, dout, empty, full);
    end

endmodule