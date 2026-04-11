`timescale 1ns / 1ps

module tb_counter_10000;
    reg clk;
    reg rst_n;
    reg stop;
    reg reset;
    reg mode_sel;

    wire [3:0] digit;
    wire [7:0] seg;

    counter_10000 u1_counter_10000 (
        .clk(clk),
        .rst_n(rst_n),
        .stop(stop),
        .reset(reset),
        .mode_sel(mode_sel),
        .digit(digit),
        .seg(seg)
    );

    always #5 clk = ~clk;

    initial begin
        $monitor("t=%0t | rst_n=%b reset=%b stop=%b mode=%b | digit=%b seg=%b",
                 $time, rst_n, reset, stop, mode_sel, digit, seg);
    end

    initial begin
        clk      = 0;
        rst_n    = 0;
        reset    = 0;
        stop     = 0;
        mode_sel = 0;

        #20;
        rst_n = 1;

        //--------------------------------
        // Scenario 1 : normal run and stop
        //--------------------------------
        stop = 1;
        #300_000_000;

        wait (u1_counter_10000.u1_data_path.w_tick_10hz == 1'b0);
        stop = 0;
        #200_000_000;

        //--------------------------------
        // Scenario 2 : stop when tick is HIGH
        //--------------------------------
        stop = 1;
        #200_000_000;
        
        // 내부 tick이 1이 되는 순간까지 대기
        wait (u1_counter_10000.u1_data_path.w_tick_10hz == 1'b1);

        // tick이 HIGH인 상태에서 stop 비활성화
        stop = 0;

        // 이후 count가 계속 증가하는 이상 동작 관찰
        #200_000_000;

        $finish;
    end

endmodule