`timescale 1ns / 1ps

module tb_counter_10000;
    reg clk;
    reg rst_n;
    reg btn_run;
    reg btn_clear;
    reg btn_mode;

    wire [3:0] digit;
    wire [7:0] seg;

    counter_10000 u1_counter_10000 (
        .clk       (clk),
        .rst_n     (rst_n),
        .btn_run   (btn_run),
        .btn_clear (btn_clear),
        .btn_mode  (btn_mode),
        .digit     (digit),
        .seg       (seg)
    );

    //------------------------------------------------------------
    // clock
    //------------------------------------------------------------
    always #5 clk = ~clk;   // 100MHz

    //------------------------------------------------------------
    // parameter
    //------------------------------------------------------------
    integer seed = 10;

    // debounce가 20ms라면 그보다 길게 눌러줘야 안전
    localparam integer PRESS_TIME = 25_000_000; // 25ms
    localparam integer GAP_TIME   = 30_000_000; // 30ms
    localparam integer BOUNCE_NS  = 1000_000;       // 1ms 간격으로 bounce

    //------------------------------------------------------------
    // clean press task
    // 동시 입력 / 우선순위 검증용
    //------------------------------------------------------------
    task press_btn;
        input t_btn_run;
        input t_btn_clear;
        input t_btn_mode;
        input integer hold_time;
        begin
            @(negedge clk);
            {btn_run, btn_clear, btn_mode} = {t_btn_run, t_btn_clear, t_btn_mode};

            #(hold_time);

            @(negedge clk);
            {btn_run, btn_clear, btn_mode} = 3'b000;
        end
    endtask

    //------------------------------------------------------------
    // bounce 포함 press task
    // 실제 버튼 노이즈 검증용
    //------------------------------------------------------------
    task press_btn_with_bounce;
        input t_btn_run;
        input t_btn_clear;
        input t_btn_mode;
        input integer bounce_count;
        input integer hold_time;
        integer i;
        begin
            @(negedge clk);

            // bounce 구간
            for (i = 0; i < bounce_count; i = i + 1) begin
                if (t_btn_run)
                    btn_run = $random(seed) & 1'b1;
                else
                    btn_run = 1'b0;

                if (t_btn_clear)
                    btn_clear = $random(seed) & 1'b1;
                else
                    btn_clear = 1'b0;

                if (t_btn_mode)
                    btn_mode = $random(seed) & 1'b1;
                else
                    btn_mode = 1'b0;

                #(BOUNCE_NS);
            end

            // 최종 안정 상태
            btn_run   = t_btn_run;
            btn_clear = t_btn_clear;
            btn_mode  = t_btn_mode;

            #(hold_time);

            @(negedge clk);
            btn_run   = 1'b0;
            btn_clear = 1'b0;
            btn_mode  = 1'b0;
        end
    endtask

    //------------------------------------------------------------
    // test
    //------------------------------------------------------------
    initial begin
        // 초기화
        clk       = 1'b0;
        rst_n     = 1'b0;
        btn_run   = 1'b0;
        btn_clear = 1'b0;
        btn_mode  = 1'b0;

        //--------------------------------------------------------
        // 시나리오 1
        // 초기 상태(IDLE) 확인 후 STOP 전이
        //--------------------------------------------------------
        repeat (5) @(posedge clk);
        rst_n = 1'b1;
        repeat (5) @(posedge clk);
        #(GAP_TIME);
        //--------------------------------------------------------
        // 시나리오 2
        // STOP -> RUN
        //--------------------------------------------------------
        press_btn_with_bounce(1, 0, 0, 5, PRESS_TIME);
        #(GAP_TIME);

        //--------------------------------------------------------
        // 시나리오 3
        // RUN 상태에서 비정상 입력(clear, mode) 무시되는지 확인
        //--------------------------------------------------------
        press_btn_with_bounce(0, 1, 0, 5, PRESS_TIME);
        #(GAP_TIME);

        press_btn_with_bounce(0, 0, 1, 5, PRESS_TIME);
        #(GAP_TIME);

        //--------------------------------------------------------
        // 시나리오 4
        // RUN -> STOP
        //--------------------------------------------------------
        press_btn_with_bounce(1, 0, 0, 5, PRESS_TIME);
        #(GAP_TIME);

        //--------------------------------------------------------
        // 시나리오 5
        // STOP -> MODE -> STOP 자동 복귀
        //--------------------------------------------------------
        press_btn_with_bounce(0, 0, 1, 5, PRESS_TIME);
        #(GAP_TIME);

        //--------------------------------------------------------
        // 시나리오 6
        // STOP -> RUN, 이전 mode 설정 유지 여부 확인
        //--------------------------------------------------------
        press_btn_with_bounce(1, 0, 0, 5, PRESS_TIME);
        #(GAP_TIME);

        //--------------------------------------------------------
        // 시나리오 7
        // RUN -> STOP -> CLEAR -> STOP
        //--------------------------------------------------------
        press_btn_with_bounce(1, 0, 0, 5, PRESS_TIME);
        #(GAP_TIME);

        press_btn_with_bounce(0, 1, 0, 5, PRESS_TIME);
        #(GAP_TIME);

        //--------------------------------------------------------
        // 시나리오 8
        // STOP에서 clear > mode > run 우선순위 검증
        // 이건 반드시 clean 동시 입력으로 확인해야 함
        //--------------------------------------------------------
        press_btn(1, 1, 1, PRESS_TIME);
        #(GAP_TIME);

        $finish;
    end

endmodule