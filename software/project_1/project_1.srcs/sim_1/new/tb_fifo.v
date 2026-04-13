`timescale 1ns / 1ps
/*
 * 시나리오 1 : empty일때 read 할 경우 -> read가 안되는 것을 확인
 * 시나리오 2 : write 할 경우 -> 정상 쓰임 확인
 * 시나리오 3 : write 가 full일 경우 -> full이 올라오면서 쓰기가 안되는 것을 확인
 * 시나리오 4 : read 할 경우 -> 정상 읽기 확인
 * 시나리오 5 : write를 해서 wrapping 확인
 */

module tb_fifo;
    reg clk;
    reg rst_n;

    reg [7:0] din;
    reg w_en;

    wire [7:0] dout;
    reg r_en;

    wire empty;
    wire full;

    fifo u1_fifo (
        .clk  (clk),
        .rst_n(rst_n),
        .din  (din),
        .w_en (w_en),
        .dout (dout),
        .r_en (r_en),
        .empty(empty),
        .full (full)
    );

    always #5 clk = ~clk;

    initial begin
        {clk, rst_n} = 2'b00;
        din = 0;
        w_en = 0;
        r_en = 0;

        repeat (5) @(posedge clk);
        rst_n = 1;
    end

    initial begin
        wait (rst_n == 1);
        repeat (2) @(posedge clk);

        // scenario 1
        @(negedge clk);
        r_en = 1;
        @(posedge clk);
        r_en = 0;
        if (empty !== 1'b1) $display("ERROR: empty should be 1 after reset");

        // scenario 2
        @(negedge clk);
        din  = 8'h11;
        w_en = 1;
        @(posedge clk);
        @(negedge clk);
        w_en = 0;
        if (empty !== 1'b0)
            $display("ERROR: empty should be 0 after one write");

        // scenario 3 : fill FIFO
        repeat (15) begin
            @(negedge clk);
            din  = din + 1;
            w_en = 1;
            @(posedge clk);
            @(posedge clk);
            w_en = 0;
        end
        if (full !== 1'b1) $display("ERROR: full should be 1 after 16 writes");

        // full 상태에서 추가 write 시도
        @(negedge clk);
        din  = 8'hAA;
        w_en = 1;
        @(posedge clk);
        w_en = 0;
        if (full !== 1'b1) $display("ERROR: full should remain 1");

        // scenario 4 : read
        @(negedge clk);
        r_en = 1;
        @(posedge clk);
        @(negedge clk);
        r_en = 0;
        $display("READ dout = %h", dout);

        // scenario 5 : wrap write
        @(negedge clk);
        din  = 8'h55;
        w_en = 1;
        @(posedge clk);
        w_en = 0;

        $finish;
    end
endmodule
