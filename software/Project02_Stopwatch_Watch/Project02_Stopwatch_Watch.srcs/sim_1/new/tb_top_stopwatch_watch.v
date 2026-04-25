`timescale 1ns / 1ps

module tb_top_stopwatch_watch;
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
            $display("[%0t] setmode=%0b sw_watch=%0b unit_sel=%0b led=%02b digit=%04b seg=%08b",
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
                $display("[%0t] SUCCESS | %s | expected=%0d actual=%0d", $time, name, expected, actual);
                pass_cnt = pass_cnt + 1;
            end
            else begin
                $display("[%0t] FAIL    | %s | expected=%0d actual=%0d", $time, name, expected, actual);
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
                $display("[%0t] SUCCESS | %s | prev=%0d actual=%0d", $time, name, prev, actual);
                pass_cnt = pass_cnt + 1;
            end
            else begin
                $display("[%0t]FAIL    | %s | value did not change | prev=%0d actual=%0d", $time, name, prev, actual);
                fail_cnt = fail_cnt + 1;
            end
        end
    endtask

    task check_true;
        input [8*64-1:0] name;
        input cond;
        begin
            if (cond) begin
                $display("[%0t] SUCCESS | %s", $time, name);
                pass_cnt = pass_cnt + 1;
            end
            else begin
                $display("[%0t] FAIL    | %s", $time, name);
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
        $display("        STOPWATCH 9-SCENARIO VERIFICATION");
        $display("==================================================");

        // ========================================================
        // SCENARIO 1 : btnL 입력 → 스톱워치 시작
        // ========================================================
        $display("\nSCENARIO 1 : START");
        prev_msec = sw_msec;
        prev_sec  = sw_sec;

        press_btnR();             // 네 기존 tb 기준 btnR이 start/stop
        #100_000_000;             // 100ms 관찰

        check_true     ("RUN state entered", sw_run == 1'b1);
        check_not_equal("msec should increase after START", prev_msec, sw_msec);

        // ========================================================
        // SCENARIO 2 : btnL 입력 → 스톱워치 정지
        // ========================================================
        $display("\nSCENARIO 2 : STOP");
        press_btnR();
        prev_msec = sw_msec;
        #50_000_000;

        check_true ("RUN state cleared after STOP", sw_run == 1'b0);
        check_equal("msec should hold after STOP", prev_msec, sw_msec);

        // ========================================================
        // SCENARIO 3 : btnR 입력 → 초기화
        // ========================================================
        $display("\nSCENARIO 3 : CLEAR");
        press_btnL();

        #10_000_000;
        check_equal("msec cleared", 0, sw_msec);
        check_equal("sec cleared" , 0, sw_sec);

        // ========================================================
        // SCENARIO 4 : btnL 입력 → 다시 시작
        // ========================================================
        $display("\nSCENARIO 4 : RESTART");
        prev_msec = sw_msec;
        press_btnR();
        #100_000_000;

        check_true     ("RUN state entered again", sw_run == 1'b1);
        check_not_equal("msec should increase after RESTART", prev_msec, sw_msec);

        // ========================================================
        // SCENARIO 5 : btnL 입력 → 정지
        // ========================================================
        $display("\nSCENARIO 5 : STOP AGAIN");
        press_btnR();
        prev_msec = sw_msec;
        #50_000_000;

        check_true ("RUN state cleared after second STOP", sw_run == 1'b0);
        check_equal("msec should hold after second STOP", prev_msec, sw_msec);

        // ========================================================
        // SCENARIO 6 : btnD 입력 → 다운 카운트 모드 전환
        // ========================================================
        $display("\nSCENARIO 6 : DOWN MODE TOGGLE");
        press_btnD();
        #10_000_000;

        check_true("down mode entered", sw_down == 1'b1);

        // ========================================================
        // SCENARIO 7 : btnL 입력 → 스톱워치 동작
        // ========================================================
        $display("\nSCENARIO 7 : START IN DOWN MODE");
        prev_msec = sw_msec;
        prev_sec  = sw_sec;

        press_btnR();
        #100_000_000;

        check_true("RUN state entered in down mode", sw_run == 1'b1);
        check_true("count should move in down mode",
                   (sw_sec < prev_sec) || ((sw_sec == prev_sec) && (sw_msec < prev_msec)));

        // ========================================================
        // SCENARIO 8 : 오버플로우 확인
        // 다운카운트에서는 00에서 최대값으로 언더플로우되는지 확인
        // ========================================================
        $display("\nSCENARIO 8 : OVERFLOW / UNDERFLOW");
        press_btnR();   // 잠깐 정지
        press_btnL();   // clear -> 0으로
        press_btnR();   // 다시 시작 (down mode 유지 가정)
        #50_000_000;

        check_true("underflow wrap observed in down mode",
                   (sw_sec != 0) || (sw_msec != 0));

        // ========================================================
        // SCENARIO 9 : btnL 입력 → 정지 + time_sel_sw 표시 전환
        // ========================================================
        $display("\nSCENARIO 9 : STOP + DISPLAY TOGGLE");
        press_btnR();    // stop
        check_true("RUN state cleared at final STOP", sw_run == 1'b0);

        prev_digit = digit;
        prev_seg   = seg;

        set_switches(0, 1, 1);   // sec/msec
        #10_000_000;

        check_equal("LED[1] should indicate sec/msec display", 1, led[1]);
        check_true ("display output should change after time_sel_sw toggle",
                    (digit != prev_digit) || (seg != prev_seg));

        $display("\n==================================================");
        $display("FINAL RESULT | PASS = %0d | FAIL = %0d", pass_cnt, fail_cnt);
        $display("==================================================");

        $finish;
    end

endmodule