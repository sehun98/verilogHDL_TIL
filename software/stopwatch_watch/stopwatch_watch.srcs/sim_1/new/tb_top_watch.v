`timescale 1ns / 1ps

module tb_top_watch;
    reg        clk;
    reg        rst_n;

    reg        btnR;  // stopwatch : run / stop
    reg        btnL;  // stopwatch : clear
    reg        btnU;  // watch : value up
    reg        btnD;  // stopwatch : down mode toggle / watch : value down

    reg        setmode_sw;           // HIGH : watch setting, LOW : run watch
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

    // ============================================================
    // clock
    // ============================================================
    always #5 clk = ~clk;   // 100MHz

    localparam integer BTN_FILTER_NS = 20_000_000;  // 20ms
    localparam integer BTN_MARGIN_NS =  5_000_000;  // 5ms margin
    localparam integer BTN_PRESS_NS  = BTN_FILTER_NS + BTN_MARGIN_NS;
    localparam integer GAP_NS        =  5_000_000;  // 5ms

    integer pass_cnt;
    integer fail_cnt;

    // ============================================================
    // DEBUG SIGNAL
    // ============================================================
    wire [6:0] sw_msec  = dut.u1_stopwatch_datapath.msec;
    wire [5:0] sw_sec   = dut.u1_stopwatch_datapath.sec;
    wire       sw_run   = dut.u1_stopwatch_datapath.run;
    wire       sw_down  = dut.u1_stopwatch_datapath.mode;

    // ============================================================
    // button press tasks
    // ============================================================
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

    // ============================================================
    // switch setting task
    // ============================================================
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

    // ============================================================
    // print task
    // ============================================================
    task print_state;
        begin
            $display("[%0f] setmode=%0b sw_watch=%0b unit_sel=%0b led=%02b digit=%04b seg=%08b",
                     $time, setmode_sw, stopwatch_watch_sw, hourmin_secmsec_sw, led, digit, seg);
        end
    endtask

    // ============================================================
    // check tasks
    // ============================================================
    task check_equal;
        input [8*64-1:0] name;
        input integer expected;
        input integer actual;
        begin
            if (expected === actual) begin
                $display("[%0f] SUCCESS | %s | expected=%0d actual=%0d", $time, name, expected, actual);
                pass_cnt = pass_cnt + 1;
            end
            else begin
                $display("[%0f] FAIL    | %s | expected=%0d actual=%0d", $time, name, expected, actual);
                fail_cnt = fail_cnt + 1;
            end
        end
    endtask

    task check_not_equal;
        input [8*64-1:0] name;
        input integer prev;
        input integer actual;
        begin
            if (prev !== actual) begin
                $display("[%0f] SUCCESS | %s | prev=%0d actual=%0d", $time, name, prev, actual);
                pass_cnt = pass_cnt + 1;
            end
            else begin
                $display("[%0f]FAIL    | %s | value did not change | prev=%0d actual=%0d", $time, name, prev, actual);
                fail_cnt = fail_cnt + 1;
            end
        end
    endtask

    task check_true;
        input [8*64-1:0] name;
        input cond;
        begin
            if (cond) begin
                $display("[%0f] SUCCESS | %s", $time, name);
                pass_cnt = pass_cnt + 1;
            end
            else begin
                $display("[%0f] FAIL    | %s", $time, name);
                fail_cnt = fail_cnt + 1;
            end
        end
    endtask

    // ============================================================
    // initial
    // ============================================================
    integer prev_msec;
    integer prev_sec;
    integer prev_digit;
    integer prev_seg;

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

        pass_cnt = 0;
        fail_cnt = 0;

        repeat (5) @(posedge clk);
        rst_n = 1;
        #(GAP_NS);

        // stopwatch 모드 진입
        set_switches(0, 1, 0);
        $display("==================================================");
        $display("      WATCH -> STOPWATCH SCENARIO VERIFICATION");
        $display("==================================================");

        // ========================================================
        // SCENARIO 1 : setmode_sw 내림 → WATCH 동작
        // ========================================================
        $display("\nSCENARIO 1 : WATCH RUN MODE");
        set_switches(0, 0, 0);   // setmode=0, watch=0, hour/min=0
        #50_000_000;

        check_equal("watch mode selected", 1, led[0]);
        print_state();

        // ========================================================
        // SCENARIO 2 : setmode_sw 올림 → 설정 모드 진입
        // ========================================================
        $display("\nSCENARIO 2 : WATCH SET MODE ENTRY");
        set_switches(1, 0, 0);
        #10_000_000;

        check_equal("still watch mode", 1, led[0]);
        check_equal("setmode_sw entered", 1, setmode_sw);
        print_state();

        // ========================================================
        // SCENARIO 3 : time_sel_sw 올림 → 시/분 표시
        // ========================================================
        $display("\nSCENARIO 3 : TIME DISPLAY SELECT");
        prev_seg   = seg;
        prev_digit = digit;

        set_switches(1, 0, 1);   // setmode=1, watch=0, sec/msec 표시
        #10_000_000;

        check_equal("sec/msec display selected", 1, led[1]);
        check_true ("display changed after time_sel toggle",
                    (digit != prev_digit) || (seg != prev_seg));
        print_state();

        // ========================================================
        // SCENARIO 4 : 자리수 변경 및 값 변경 확인
        // ========================================================
        $display("\nSCENARIO 4 : DIGIT / VALUE CHANGE");
        prev_seg = seg;

        // 자릿수 이동
        press_btnR();
        #10_000_000;

        // 값 증가
        press_btnU();
        #10_000_000;

        check_true("display changed after digit/value update", seg != prev_seg);
        print_state();

        // 필요하면 감소도 같이 검증
        prev_seg = seg;
        press_btnL();
        #10_000_000;
        press_btnD();
        #10_000_000;

        check_true("display changed after left/down update", seg != prev_seg);
        print_state();

        // ========================================================
        // SCENARIO 5 : setmode_sw 내림 → WATCH 동작
        // ========================================================
        $display("\nSCENARIO 5 : EXIT SET MODE -> WATCH RUN");
        set_switches(0, 0, 1);
        #50_000_000;

        check_equal("setmode exited", 0, setmode_sw);
        check_equal("watch mode maintained", 1, led[0]);
        print_state();

        // ========================================================
        // SCENARIO 6 : stopwatch_watch_sw 올림 → 스톱워치 전환
        // ========================================================
        $display("\nSCENARIO 6 : SWITCH TO STOPWATCH");
        set_switches(0, 1, 1);
        #10_000_000;

        // led[0] : HIGH watch, LOW stopwatch 라는 주석 기준
        check_equal("stopwatch mode selected", 0, led[0]);
        print_state();

        // ========================================================
        // SCENARIO 7 : btnR → 스톱워치 START
        // ========================================================
        $display("\nSCENARIO 7 : STOPWATCH START");
        prev_msec = sw_msec;
        prev_sec  = sw_sec;

        press_btnR();
        #100_000_000;

        check_true     ("RUN state entered", sw_run == 1'b1);
        check_not_equal("msec increased after stopwatch start", prev_msec, sw_msec);
        print_state();

        // ========================================================
        // SCENARIO 8 : btnD → DOWN COUNT
        // ========================================================
        $display("\nSCENARIO 8 : STOPWATCH DOWN COUNT MODE");
        press_btnR();    // 일단 정지
        #10_000_000;
        check_true("RUN cleared before down mode toggle", sw_run == 1'b0);

        press_btnD();    // down mode 진입
        #10_000_000;
        check_true("down mode entered", sw_down == 1'b1);

        prev_msec = sw_msec;
        prev_sec  = sw_sec;

        press_btnR();    // down mode에서 start
        #100_000_000;

        check_true("RUN entered in down mode", sw_run == 1'b1);
        check_true("count decreased in down mode",
                   (sw_sec < prev_sec) || ((sw_sec == prev_sec) && (sw_msec < prev_msec)));
        print_state();

        $display("\n==================================================");
        $display("FINAL RESULT | PASS = %0d | FAIL = %0d", pass_cnt, fail_cnt);
        $display("==================================================");
        
        $finish;
    end

endmodule