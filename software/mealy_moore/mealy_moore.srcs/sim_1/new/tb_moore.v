`timescale 1ns / 1ps

module tb_moore;
    reg  clk;
    reg  rst_n;
    reg  din;
    wire dout;

    mealy u1_mealy (
        .clk  (clk),
        .rst_n(rst_n),
        .din  (din),
        .dout (dout)
    );

    always #5 clk = ~clk;
    /*
1 0 1 0   // detect
1 0       // incomplete
0 0       // garbage
1 0 1 0   // detect
1 1 1     // no detect
1 0 1 0   // detect
0 1 0     // incomplete
1 0 1 0   // detect

1 0 1 0 1 0 0 0 1 0 1 0 1 1 1 1 0 1 0 0 1 0 1 0
0 0 0 1 0 0 0 0 0 0 0 1 0 0 0 0 0 0 1 0 0 0 0 1
    */
reg expected_d;

task bit_setting;
    input bit_set;
    input bit_result;
    begin
        @(negedge clk);
        din = bit_set;

        @(posedge clk);   // 이 posedge에서 state 갱신
        #1;               // 조합 출력 안정화 대기

        if (dout == bit_result)
            $display("SUCCESS > din : %0d, dout : %0d, expected : %0d", din, dout, bit_result);
        else
            $display("FAIL    > din : %0d, dout : %0d, expected : %0d", din, dout, bit_result);
    end
endtask

    initial begin
        {clk, rst_n} = 2'b00;
        din = 0;
        repeat (5) @(posedge clk);
        rst_n = 1;
        @(posedge clk);
        // 시나리오 1 : detect
        bit_setting(1, 0);
        bit_setting(0, 0);
        bit_setting(1, 0);
        bit_setting(0, 1);

        // 시나리오 2 : incomplete
        bit_setting(1, 0);
        bit_setting(0, 0);

        // 시나리오 3 : garbage
        bit_setting(0, 0);
        bit_setting(0, 0);

        // 시나리오 4 : detect
        bit_setting(1, 0);
        bit_setting(0, 0);
        bit_setting(1, 0);
        bit_setting(0, 1);

        // 시나리오 5 : no detect
        bit_setting(1, 0);
        bit_setting(1, 0);
        bit_setting(1, 0);

        // 시나리오 6 : detect
        bit_setting(1, 0);
        bit_setting(0, 0);
        bit_setting(1, 0);
        bit_setting(0, 1);

        // 시나리오 7 : incomplete & detect
        bit_setting(0, 0);
        bit_setting(1, 0);
        bit_setting(0, 0);
        bit_setting(1, 0);
        bit_setting(0, 1);
        $finish;
    end

endmodule
