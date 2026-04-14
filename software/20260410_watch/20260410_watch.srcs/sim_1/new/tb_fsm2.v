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
        clk   = 0;
        rst_n = 0;
        repeat (5) @(posedge clk);
        rst_n = 1;

        sw = 2'b01;
        #1000_000;
        sw = 2'b10;
        #1000_000;
        sw = 2'b11;
        #1000_000;
    end

endmodule

module tb_fsm4;
    reg clk;
    reg rst_n;
    reg [2:0] sw;
    wire [2:0] led;

    fsm3 u1_fsm4 (
        .clk(clk),
        .rst_n(rst_n),
        .sw(sw),
        .led(led)
    );

    // 시나리오 1 : A 전원 상태에서 LED가 모두 꺼진지 확인
    // 시나리오 2 : sw=3'b001이 인가될 때 led[0]이 켜지는지 확인
    // 시나리오 3 : sw=3'b010이 인가될 때 led[1]이 켜지는지 확인
    // 시나리오 4 : sw=3'b100이 인가될 때 led[2]이 켜지는지 확인

    // 시나리오 5 : sw=3'b111이 인가될 때 led all 켜지는지 확인

    // 시나리오 6 : sw=3'b000이 인가될 때 led off 꺼지는지 확인

    // 시나리오 7 : sw=3'b010이 인가될 때 led[1]이 켜지는지 확인

    // 시나리오 8 : sw=3'b100이 인가될 때 led[2]이 켜지는지 확인
    //           : sw=3'b000이 인가될 때 led off 꺼지는지 확인

    // 시나리오 9 : sw=3'b001이 인가될 때 led[0]이 켜지는지 확인
    //           : sw=3'b010이 인가될 때 led[1]이 꺼지는지 확인
    //           : sw=3'b001이 인가될 때 led[0]이 꺼지는지 확인

    always #5 clk = ~clk;
    initial begin
        clk   = 0;
        rst_n = 0;
        repeat (5) @(posedge clk);
        rst_n = 1;

        // 시나리오 1 : A 전원 상태에서 LED가 모두 꺼진지 확인
        #1000_000;

        // 시나리오 2 : sw=3'b001이 인가될 때 led[0]이 켜지는지 확인
        sw = 3'b001;
        #1000_000;

        // 시나리오 3 : sw=3'b010이 인가될 때 led[1]이 켜지는지 확인
        sw = 3'b010;
        #1000_000;

        // 시나리오 4 : sw=3'b100이 인가될 때 led[2]이 켜지는지 확인
        sw = 3'b100;
        #1000_000;
        // 시나리오 5 : sw=3'b111이 인가될 때 led all 켜지는지 확인
        sw = 3'b111;
        #1000_000;
        // 시나리오 6 : sw=3'b000이 인가될 때 led off 꺼지는지 확인
        sw = 3'b000;
        #1000_000;
        // 시나리오 7 : sw=3'b010이 인가될 때 led[1]이 켜지는지 확인
        sw = 3'b010;
        #1000_000;
        // 시나리오 8 : sw=3'b100이 인가될 때 led[2]이 켜지는지 확인
        //           : sw=3'b000이 인가될 때 led off 꺼지는지 확인
        sw = 3'b100;
        sw = 3'b000;
        #1000_000;
        // 시나리오 9 : sw=3'b001이 인가될 때 led[0]이 켜지는지 확인
        //           : sw=3'b010이 인가될 때 led[1]이 꺼지는지 확인
        //           : sw=3'b001이 인가될 때 led[0]이 꺼지는지 확인
        sw = 3'b001;
        sw = 3'b010;
        sw = 3'b001;
        #1000_000;
    end

endmodule

`timescale 1ns / 1ps

module tb_fsm10;

    // 입력 신호 선언
    reg clk;
    reg rst;
    reg din_bit;

    // 출력 신호 선언
    wire dout_bit;

    // DUT 인스턴스화
    fsm11 u1_fsm11 (
        .clk(clk),
        .rst(rst),
        .din_bit(din_bit),
        .dout_bit(dout_bit)
    );

    // 클럭 생성 (예: 10ns 주기)
    always #5 clk = ~clk;

    initial begin
        // 초기값 설정
        clk = 0;
        rst = 1;
        din_bit = 0;

        // 리셋 신호
        #15 rst = 0;

        // 입력 신호 패턴 (예시)
        #5  din_bit = 1;
        #30 din_bit = 0;
        #10 din_bit = 1;
        #20 din_bit = 0;
        #40 din_bit = 1;
        #10 din_bit = 0;
        #30 din_bit = 1;
        #40 din_bit = 0;
        #10 din_bit = 1;
        #10 din_bit = 0;
        #30 din_bit = 1;
        #20 din_bit = 0;

        // 시뮬레이션 종료
        #100 $finish;
    end

endmodule
