`timescale 1ns / 1ps

module tb_top_stopwatch_watch;
    reg        clk;
    reg        rst_n;

    reg        btnR;  // stopwatch : run       / watch : 자릿수 오른쪽
    reg        btnL;  // stopwatch : clear     / watch : 자릿수 왼쪽
    reg        btnU;  // stopwatch : X         / watch : 값 Up
    reg        btnD;  // stopwatch : mode      / watch : 값 Down

    reg        setmode_sw;           // HIGH : setting watch, LOW : run watch
    reg        stopwatch_watch_sw;   // HIGH : stopwatch, LOW : watch
    reg        hourmin_secmsec_sw;   // HIGH : sec/msec, LOW : hour/min

    wire [7:0] seg;
    wire [3:0] digit;
    wire [1:0] led;
    // led[0] HIGH : watch, LOW : stopwatch
    // led[1] HIGH : sec/msec, LOW : hour/min

    top_stopwatch_watch dut (
        .clk                (clk),
        .rst_n              (rst_n),
        .btnR               (btnR),
        .btnL               (btnL),
        .btnU               (btnU),
        .btnD               (btnD),
        .setmode_sw         (setmode_sw),
        .stopwatch_watch_sw (stopwatch_watch_sw),
        .hourmin_secmsec_sw (hourmin_secmsec_sw),
        .seg                (seg),
        .digit              (digit),
        .led                (led)
    );

    // 100MHz clock
    always #5 clk = ~clk;

    localparam integer BTN_FILTER_NS = 20_000_000;  // 20ms
    localparam integer BTN_MARGIN_NS =  1_000_000;  // 1ms margin
    localparam integer BTN_PRESS_NS  = BTN_FILTER_NS + BTN_MARGIN_NS;
    localparam integer GAP_NS        =  5_000_000;  // 5ms

    // ------------------------------------------------------------
    // button press tasks
    // ------------------------------------------------------------
    task press_btnR;
        begin
            @(negedge clk);
            btnR = 1'b1;
            #(BTN_PRESS_NS);
            @(negedge clk);
            btnR = 1'b0;
            #(GAP_NS);
        end
    endtask

    task press_btnL;
        begin
            @(negedge clk);
            btnL = 1'b1;
            #(BTN_PRESS_NS);
            @(negedge clk);
            btnL = 1'b0;
            #(GAP_NS);
        end
    endtask

    task press_btnU;
        begin
            @(negedge clk);
            btnU = 1'b1;
            #(BTN_PRESS_NS);
            @(negedge clk);
            btnU = 1'b0;
            #(GAP_NS);
        end
    endtask

    task press_btnD;
        begin
            @(negedge clk);
            btnD = 1'b1;
            #(BTN_PRESS_NS);
            @(negedge clk);
            btnD = 1'b0;
            #(GAP_NS);
        end
    endtask

    // ------------------------------------------------------------
    // switch setting task
    // ------------------------------------------------------------
    task set_switches;
        input t_setmode_sw;
        input t_stopwatch_watch_sw;
        input t_hourmin_secmsec_sw;
        begin
            @(negedge clk);
            setmode_sw          = t_setmode_sw;
            stopwatch_watch_sw  = t_stopwatch_watch_sw;
            hourmin_secmsec_sw  = t_hourmin_secmsec_sw;
            #(GAP_NS);
        end
    endtask

    // ------------------------------------------------------------
    // simple monitor task
    // ------------------------------------------------------------
    task print_state;
        begin
            $display("[%0t] | setmode=%0b sw_watch=%0b unit_sel=%0b led=%02b digit=%04b seg=%08b", $time, setmode_sw, stopwatch_watch_sw, hourmin_secmsec_sw, led, digit, seg);
        end
    endtask

    // ------------------------------------------------------------
    // initial
    // ------------------------------------------------------------
    initial begin
        clk = 0;
        rst_n = 0;
        btnR = 0;
        btnL = 0;
        btnU = 0;
        btnD = 0;
        setmode_sw = 0;
        stopwatch_watch_sw = 0;   // watch
        hourmin_secmsec_sw = 0;   // hour/min

        repeat (5) @(posedge clk);
        rst_n = 1;
        #(GAP_NS);

        // ============================================================
        // 정상 동작 시나리오 watch
        // ============================================================
        $display("============================= watch change =============================");

        // 시나리오 1 : reset 초기화 검증
        $display("TIME %d | SCENARIO 1 : reset release", $time);

        // 시나리오 2 : watch 모드 기본 동작 검증
        // stopwatch_watch_sw=0일 때 watch 시간이 정상 증가하는지 확인
        $display("TIME %d | SCENARIO 2 : watch mode", $time);
        set_switches(0, 0, 0);
        
        // 시나리오 3 : watch 표시 단위 선택 검증
        // hour/min <-> sec/msec 표시 전환
        $display("TIME %d | SCENARIO 3-1 : watch hour/min", $time);
        set_switches(0, 0, 0);
        $display("TIME %d | SCENARIO 3-2 : watch sec/msec", $time);
        set_switches(0, 0, 1);

        // 시나리오 4 : watch set mode 진입 검증
        $display("TIME %d | SCENARIO 4 : watch set mode entry", $time);
        set_switches(1, 0, 0);

        // 시나리오 5 : watch digit 선택 이동 검증
        $display("TIME %d | SCENARIO 5-1 : digit right", $time);
        press_btnR();
        $display("TIME %d | SCENARIO 5-2 : digit left", $time);
        press_btnL();

        // 시나리오 6 : watch 시간 증가/감소 검증
        $display("TIME %d | SCENARIO 6-1 : value up", $time);
        press_btnU();
        $display("TIME %d | SCENARIO 6-2 : value down", $time);
        press_btnD();

        // 시나리오 7 : watch set mode 해제 검증
        $display("TIME %d | SCENARIO 7 : watch set mode exit", $time);
        set_switches(0, 0, 0);

        // ============================================================
        // 정상 동작 시나리오 watch -> stopwatch
        // ============================================================
        $display("============================= mode change =============================");
        // 시나리오 1 : stopwatch 모드 전환 검증
        $display("TIME %d | SCENARIO 1 : stopwatch mode", $time);
        set_switches(0, 1, 0);

        // ============================================================
        // 정상 동작 시나리오 stopwatch
        // ============================================================
        $display("============================= stopwatch mode =============================");
        // 시나리오 1 : stopwatch 시작 검증
        $display("TIME %d | SCENARIO 1 : stopwatch start", $time);
        press_btnR();
        #100_000_000; // 100ms 정도 동작 관찰

        // 시나리오 2 : stopwatch 정지 검증
        $display("TIME %d | SCENARIO 2 : stopwatch stop", $time);
        press_btnR();
        #20_000_000;

        // 시나리오 3 : stopwatch clear 검증
        $display("TIME %d | SCENARIO 3 : stopwatch clear", $time);
        press_btnL();

        // 시나리오 4 : stopwatch 내부 mode 전환 검증
        $display("TIME %d | SCENARIO 4 : stopwatch inner mode toggle", $time);
        press_btnD();

        // 시나리오 4-1/2 : watch/stopwatch 전환 검증
        $display("TIME %d | SCENARIO 4-1 : back to watch", $time);
        set_switches(0, 0, 0);
        $display("TIME %d | SCENARIO 4-2 : back to stopwatch sec/msec", $time);
        set_switches(0, 1, 1);

        // 시나리오 5 : FND digit 스캔 검증
        // 파형으로 digit, seg 순환 확인
        $display("TIME %d | SCENARIO 5 : FND scan observe", $time);
        #5_000_000;

        // 시나리오 6 : dot 점멸 동작 검증
        // 파형에서 seg의 dot bit 또는 관련 내부 신호 확인 권장
        $display("TIME %d | SCENARIO 6 : dot blink observe", $time);
        set_switches(0, 0, 0);
        #600_000_000; // 0.6s 관찰

        // ============================================================
        // 예외 / 경계 시나리오
        // ============================================================

        $display("============================= mode change =============================");
        // 시나리오 1 : watch digit 선택 overflow 검증
        $display("TIME %d | SCENARIO 1 : digit right overflow", $time);
        set_switches(1, 0, 0);
        press_btnR();
        press_btnR();
        press_btnR();
        press_btnR();
        press_btnR();
        press_btnR();
        press_btnR();
        press_btnR();

        // 시나리오 2 : watch digit 선택 underflow 검증
        $display("TIME %d | SCENARIO 2 : digit left underflow", $time);
        press_btnL();

        // 시나리오 3 : watch 시간 설정 overflow 검증
        // 특정 자리 선택 후 Up 반복, 파형으로 rollover 확인
        $display("TIME %d | SCENARIO 3 : watch setting overflow", $time);
        press_btnU();
        press_btnU();
        press_btnU();

        // 시나리오 4 : watch 시간 설정 underflow 검증
        $display("TIME %d | SCENARIO 4 : watch setting underflow", $time);
        press_btnD();
        press_btnD();
        press_btnD();

        // 시나리오 5 : stopwatch 시간 overflow 검증
        $display("TIME %d | SCENARIO 5 : stopwatch carry", $time);
        set_switches(0, 1, 1);
        press_btnR();
        #1_200_000_000; // 1.2s 관찰
        press_btnR();

        // 시나리오 6 : watch 시간 overflow 검증
        // watch current time을 직접 preload할 수 없으면 장시간 시뮬 대신 별도 unit tb 권장
        $display("TIME %d | SCENARIO 6 : watch carry/overflow observe", $time);
        set_switches(0, 0, 0);

        // 시나리오 7 : 버튼 demux 예외 검증
        $display("TIME %d | SCENARIO 7-1 : btnU ignored in stopwatch", $time);
        set_switches(0, 1, 0);
        press_btnU(); // stopwatch에선 영향 거의 없어야 함
        $display("TIME %d | SCENARIO 7-2 : btnR goes to watch control only", $time);
        set_switches(0, 0, 0);
        press_btnR();

        // 시나리오 8 : setmode 전환 중 버튼 입력 검증
        $display("TIME %d | SCENARIO 8 : setmode transition with button", $time);
        @(negedge clk);
        setmode_sw = 1;
        btnR = 1;
        #(BTN_PRESS_NS);
        @(negedge clk);
        btnR = 0;
        #(GAP_NS);

        // 시나리오 9 : watch/stopwatch 전환 중 버튼 입력 검증
        $display("TIME %d | SCENARIO 9 : mode transition with button", $time);
        @(negedge clk);
        stopwatch_watch_sw = 1;
        btnL = 1;
        #(BTN_PRESS_NS);
        @(negedge clk);
        btnL = 0;
        #(GAP_NS);

        // 시나리오 10 : set mode에서 dot 점멸 유지 검증
        $display("TIME %d | SCENARIO 10 : dot blink in set mode", $time);
        set_switches(1, 0, 0);
        #600_000_000;

        $finish;
    end

endmodule