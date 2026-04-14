`timescale 1ns / 1ps

module tb_control_unit;
    reg  clk;
    reg  rst_n;
    reg  btn_run;
    reg  btn_clear;
    reg  btn_mode;

    wire run;
    wire clear;
    wire mode;

    control_unit u1_control_unit (
        .clk(clk),
        .rst_n(rst_n),
        .btn_run(btn_run),
        .btn_clear(btn_clear),
        .btn_mode(btn_mode),
        .run(run),
        .clear(clear),
        .mode(mode)
    );

    always #5 clk = ~clk;

    // 시나리오 1 : 초기 상태(IDLE)에서 run, clear, mode 출력이 모두 0인지 확인
    //             이후 1클럭 후 STOP 상태로 정상 전이되는지 검증

    // 시나리오 2 : STOP 상태에서 btn_run=1 입력 시 RUN 상태로 전이되는지 확인

    // 시나리오 3 : RUN 상태에서 비정상 입력(btn_clear, btn_mode)에 대해
    //             상태 전이가 발생하지 않고 RUN 상태가 유지되는지 검증

    // 시나리오 4 : RUN 상태에서 btn_run=0 입력 시 STOP 상태로 정상 복귀하는지 확인

    // 시나리오 5 : STOP 상태에서 btn_mode=1 입력 시 MODE 상태로 전이되는지 확인
    //             또한 mode 출력이 정상적으로 활성화되는지 검증
    //             이후 MODE 상태에서 1클럭 후 자동으로 STOP 상태로 복귀하는지 확인

    // 시나리오 6 : STOP 상태에서 btn_run=1 입력 시 RUN 상태로 전이되면서
    //             이전 mode 설정이 유지되는지 검증

    // 시나리오 7 : RUN 상태에서 STOP 상태로 복귀 확인
    //             이후 STOP 상태에서 btn_clear=1 입력 시 CLEAR 상태로 전이되는지 확인
    //             CLEAR 동작이 1클럭 동안 pulse 형태로 발생하는지 검증하고
    //             이후 STOP 상태로 정상 복귀하는지 확인

    // 시나리오 8 : 우선 순위 확인
    //             STOP에서 clear > mode > run 순의 우선 순위를 확인하기 위에 동시 신호 인가
    task btn_setting;
        input t_btn_run, t_btn_clear, t_btn_mode;
        begin
            @(negedge clk);
            {btn_run, btn_clear, btn_mode} = {
                t_btn_run, t_btn_clear, t_btn_mode
            };
            @(posedge clk);
            @(negedge clk);
            {btn_run, btn_clear, btn_mode} = 3'b000;
        end
    endtask

    initial begin
    // 시나리오 1 : 초기 상태(IDLE)에서 run, clear, mode 출력이 모두 0인지 확인
    //             이후 1클럭 후 STOP 상태로 정상 전이되는지 검증
        {clk, rst_n} = 2'b00;
        btn_setting(0, 0, 0);
        repeat(5) @(posedge clk); 
        rst_n = 1;
        #100;

    // 시나리오 2 : STOP 상태에서 btn_run=1 입력 시 RUN 상태로 전이되는지 확인        
        btn_setting(1,0,0);
        #100;
    // 시나리오 3 : RUN 상태에서 비정상 입력(btn_clear, btn_mode)에 대해
    //             상태 전이가 발생하지 않고 RUN 상태가 유지되는지 검증
        btn_setting(0,1,0);
        #100;
        btn_setting(0,0,1);
        #100;
    // 시나리오 4 : RUN 상태에서 btn_run=1 입력 시 STOP 상태로 정상 복귀하는지 확인
        btn_setting(1,0,0);
        #100; // 10ms
    // 시나리오 5 : STOP 상태에서 btn_mode=1 입력 시 MODE 상태로 전이되는지 확인
    //             또한 mode 출력이 정상적으로 활성화되는지 검증
    //             이후 MODE 상태에서 1클럭 후 자동으로 STOP 상태로 복귀하는지 확인
        btn_setting(0,0,1);
        #100;
    // 시나리오 6 : STOP 상태에서 btn_run=1 입력 시 RUN 상태로 전이되면서
    //             이전 mode 설정이 유지되는지 검증
        btn_setting(1,0,0);
        #100;
    // 시나리오 7 : RUN 상태에서 STOP 상태로 복귀 확인
    //             이후 STOP 상태에서 btn_clear=1 입력 시 CLEAR 상태로 전이되는지 확인
    //             CLEAR 동작이 1클럭 동안 pulse 형태로 발생하는지 검증하고
    //             이후 STOP 상태로 정상 복귀하는지 확인
        btn_setting(1,0,0);
        #100;        
        btn_setting(0,1,0);
        #100;
    // 시나리오 8 : 우선 순위 확인
    //             STOP에서 clear > mode > run 순의 우선 순위를 확인하기 위에 동시 신호 인가
        btn_setting(1,1,1);
        #100;
        $finish;
    end

endmodule
