`timescale 1ns / 1ps

module tb_fsm2;
    reg clk;
    reg rst_n;
    reg [1:0] sw;
    wire [2:0] led;

    fsm2 u1_fsm2 (
    .clk(clk),
    .rst_n(rst_n),
    .sw(sw),
    .led(led)
    );

    always #5 clk = ~clk;
    initial begin
        clk = 0;
        rst_n = 0;
        repeat(5) @(posedge clk);
        rst_n = 1;

        sw = 2'b01;
        #1000_000;
        sw = 2'b10;
        #1000_000;
        sw = 2'b11;
        #1000_000;
    end

endmodule
`timescale 1ns / 1ps

module tb_fsm3;
    reg clk;
    reg rst_n;
    reg [2:0] sw;
    wire [2:0] led;

    fsm3 u1_fsm3 (
        .clk(clk),
        .rst_n(rst_n),
        .sw(sw),
        .led(led)
    );

    always #5 clk = ~clk;

    initial begin
        clk   = 0;
        rst_n = 0;
        sw    = 3'b000;

        repeat(5) @(posedge clk);
        rst_n = 1;

        // 시나리오 1 : 초기 상태에서 LED 모두 OFF 확인
        sw = 3'b000;
        #100;
        if (led !== 3'b000) $display("SCENARIO 1 FAIL: led=%b", led);
        else                $display("SCENARIO 1 PASS: led=%b", led);

        // 시나리오 2 : sw=001 -> led[0] ON
        sw = 3'b001;
        #100;
        if (led !== 3'b001) $display("SCENARIO 2 FAIL: led=%b", led);
        else                $display("SCENARIO 2 PASS: led=%b", led);

        // 시나리오 3 : sw=010 -> led[1] ON
        sw = 3'b010;
        #100;
        if (led !== 3'b010) $display("SCENARIO 3 FAIL: led=%b", led);
        else                $display("SCENARIO 3 PASS: led=%b", led);

        // 시나리오 4 : sw=100 -> led[2] ON
        sw = 3'b100;
        #100;
        if (led !== 3'b100) $display("SCENARIO 4 FAIL: led=%b", led);
        else                $display("SCENARIO 4 PASS: led=%b", led);

        // 시나리오 5 : sw=111 -> LED ALL ON
        sw = 3'b111;
        #100;
        if (led !== 3'b111) $display("SCENARIO 5 FAIL: led=%b", led);
        else                $display("SCENARIO 5 PASS: led=%b", led);

        // 시나리오 6 : sw=000 -> LED ALL OFF
        sw = 3'b000;
        #100;
        if (led !== 3'b000) $display("SCENARIO 6 FAIL: led=%b", led);
        else                $display("SCENARIO 6 PASS: led=%b", led);

        // 시나리오 7 : sw=010 -> led[1] ON
        sw = 3'b010;
        #100;
        if (led !== 3'b010) $display("SCENARIO 7 FAIL: led=%b", led);
        else                $display("SCENARIO 7 PASS: led=%b", led);

        // 시나리오 8-1 : sw=100 -> led[2] ON
        sw = 3'b100;
        #100;
        if (led !== 3'b100) $display("SCENARIO 8-1 FAIL: led=%b", led);
        else                $display("SCENARIO 8-1 PASS: led=%b", led);

        // 시나리오 8-2 : sw=000 -> LED ALL OFF
        sw = 3'b000;
        #100;
        if (led !== 3'b000) $display("SCENARIO 8-2 FAIL: led=%b", led);
        else                $display("SCENARIO 8-2 PASS: led=%b", led);

        // 시나리오 9-1 : sw=001 -> led[0] ON
        sw = 3'b001;
        #100;
        if (led !== 3'b001) $display("SCENARIO 9-1 FAIL: led=%b", led);
        else                $display("SCENARIO 9-1 PASS: led=%b", led);

        // 시나리오 9-2 : sw=010 -> led[1] ON
        sw = 3'b010;
        #100;
        if (led !== 3'b010) $display("SCENARIO 9-2 FAIL: led=%b", led);
        else                $display("SCENARIO 9-2 PASS: led=%b", led);

        // 시나리오 9-3 : sw=001 -> led[0] ON
        sw = 3'b001;
        #100;
        if (led !== 3'b001) $display("SCENARIO 9-3 FAIL: led=%b", led);
        else                $display("SCENARIO 9-3 PASS: led=%b", led);

        $finish;
    end

endmodule