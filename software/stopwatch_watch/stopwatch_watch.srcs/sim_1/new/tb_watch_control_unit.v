`timescale 1ns / 1ps

// 정상 동작 시나리오 :
// 각 버튼과 set_mode에 따라 digit_sel, up, down이 의도대로 출력되는지 검증

// 시나리오 1 : 초기값 검증
// rst_n=0 또는 set_mode=0일 때 digit_sel=0, up=0, down=0인지 검증

// 시나리오 2 : run mode 유지 검증
// set_mode=0 상태에서 btn_right, btn_left, btn_up, btn_down을 눌러도
// digit_sel=0, up=0, down=0 유지되는지 검증

// 시나리오 3 : set mode 진입 검증
// set_mode=1로 전환 후 digit_sel이 기존값(초기엔 0)으로 유지되며
// 좌우/상하 버튼 입력을 받을 수 있는 상태가 되는지 검증

// 시나리오 4 : set mode 상태에서 right 버튼 검증
// btn_right 입력 시 digit_sel이 1 증가하는지 검증

// 시나리오 5 : set mode 상태에서 right overflow 검증
// digit_sel=7 상태에서 btn_right 입력 시 digit_sel이 0으로 순환하는지 검증

// 시나리오 6 : set mode 상태에서 left 버튼 검증
// btn_left 입력 시 digit_sel이 1 감소하는지 검증

// 시나리오 7 : set mode 상태에서 left overflow 검증
// digit_sel=0 상태에서 btn_left 입력 시 digit_sel이 7로 순환하는지 검증

// 시나리오 8 : set mode 상태에서 up 출력 검증
// set_mode=1, btn_up=1일 때 up=1, down=0인지 검증

// 시나리오 9 : set mode 상태에서 down 출력 검증
// set_mode=1, btn_down=1일 때 down=1, up=0인지 검증

// 시나리오 10 : set mode 해제 검증
// 동작 중 set_mode=0으로 전환하면 digit_sel이 즉시 0으로 초기화되고
// up=0, down=0이 되는지 검증


// 비정상(예외/경계) 동작 시나리오 :

// 시나리오 1 : set_mode 전환 경계 검증
// run mode -> set mode 전환 순간, 또는 set mode -> run mode 전환 순간에
// 버튼이 동시에 들어와도 digit_sel 초기화/유지 동작이 의도대로 수행되는지 검증

// 시나리오 2 : set mode 상태에서 right/left 동시 입력 검증
// btn_right=1, btn_left=1 동시 입력 시 if-else 우선순위에 의해
// right가 우선 적용되어 digit_sel이 증가하는지 검증

// 시나리오 3 : set mode 상태에서 up/down 동시 입력 검증
// btn_up=1, btn_down=1 동시 입력 시 up=1, down=1이 동시에 출력되는지 검증

// 시나리오 4 : set mode 상태에서 right/up 또는 left/down 동시 입력 검증
// digit_sel 이동과 up/down 출력이 서로 독립적으로 정상 동작하는지 검증
// 예: btn_right=1, btn_up=1이면 digit_sel 증가와 up=1이 동시에 성립하는지 검증

// 시나리오 5 : 버튼 장입력(hold) 검증
// btn_right 또는 btn_left를 여러 클럭 동안 유지하면 클럭마다 digit_sel이 연속 변경되는지 검증
// (디바운스/원펄스 회로가 없으므로 현재 구조상 연속 변경이 정상 동작임)

// 시나리오 6 : set_mode=0 상태에서 up/down 버튼 입력 검증
// btn_up 또는 btn_down이 입력되어도 up=0, down=0으로 유지되는지 검증

// 시나리오 7 : reset 우선 동작 검증
// set_mode=1 또는 버튼 입력 중 rst_n=0이 들어오면 digit_sel이 0으로 초기화되는지 검증

module tb_watch_control_unit;
    reg        clk;
    reg        rst_n;

    reg        btn_right;
    reg        btn_left;
    reg        btn_down;
    reg        btn_up;

    reg        set_mode;

    wire [2:0] digit_sel;
    wire       up;
    wire       down;

    control_unit_watch u1_control_unit_watch (
        .clk  (clk),
        .rst_n(rst_n),

        .btn_right(btn_right),
        .btn_left(btn_left),
        .btn_down(btn_down),
        .btn_up(btn_up),

        .set_mode(set_mode),
        .digit_sel(digit_sel),
        .up(up),
        .down(down)
    );

    always #5 clk = ~clk;

    task result_comparator;
        input t_btn_right;
        input t_btn_left;
        input t_btn_up;
        input t_btn_down;
        input t_set_mode;

        input [2:0] r_digit_sel;
        input r_up;
        input r_down;

        input delay;
        begin
            @(negedge clk);
            btn_right = t_btn_right;
            btn_left = t_btn_left;
            btn_up = t_btn_up;
            btn_down = t_btn_down;
            set_mode = t_set_mode;
            @(posedge clk);
            #1;
            if ((digit_sel == r_digit_sel) && (up == r_up) && (down == r_down))
                $display(
                    "SUCCESS %0t : digit_sel = %0d, up = %0b, down = %0b",
                    $time,
                    digit_sel,
                    up,
                    down
                );
            else
                $display(
                    "FAIL %0t : digit_sel = %0d (exp = %0d), up = %0b (exp = %0b), down = %0b (exp = %0b)",
                    $time,
                    digit_sel,
                    r_digit_sel,
                    up,
                    r_up,
                    down,
                    r_down
                );
            @(negedge clk);
            btn_right = 0;
            btn_left = 0;
            btn_down = 0;
            btn_up = 0;

            #(delay);
        end
    endtask

    initial begin
        clk = 0;
        rst_n = 0;

        btn_right = 0;
        btn_left = 0;
        btn_down = 0;
        btn_up = 0;

        set_mode = 0;

        repeat (5) @(posedge clk);
        rst_n = 1;

        // 정상 동작 시나리오 :
        // 각 버튼과 set_mode에 따라 digit_sel, up, down이 의도대로 출력되는지 검증

        // 시나리오 1 : 초기값 검증
        // rst_n=0 또는 set_mode=0일 때 digit_sel=0, up=0, down=0인지 검증
        $strobe("================================= NORMAL OPERATION SCENARIO =================================");
        $strobe("SCENARIO 1");
        result_comparator(0, 0, 0, 0, 0, 0, 0, 0, 100);

        // 시나리오 2 : run mode 유지 검증
        // set_mode=0 상태에서 btn_right, btn_left, btn_up, btn_down을 눌러도
        // digit_sel=0, up=0, down=0 유지되는지 검증
        $strobe("SCENARIO 2");
        result_comparator(1, 0, 0, 0, 0, 0, 0, 0, 100);
        result_comparator(0, 1, 0, 0, 0, 0, 0, 0, 100);
        result_comparator(0, 0, 1, 0, 0, 0, 0, 0, 100);
        result_comparator(0, 0, 0, 1, 0, 0, 0, 0, 100);

        // 시나리오 3 : set mode 진입 검증
        // set_mode=1로 전환 후 digit_sel이 기존값(초기엔 0)으로 유지되며
        // 좌우/상하 버튼 입력을 받을 수 있는 상태가 되는지 검증
        $strobe("SCENARIO 3");
        result_comparator(0, 0, 0, 0, 1, 0, 0, 0, 100);

        // 시나리오 4 : set mode 상태에서 right 버튼 검증
        // btn_right 입력 시 digit_sel이 1 증가하는지 검증
        $strobe("SCENARIO 4");
        result_comparator(1, 0, 0, 0, 1, 1, 0, 0, 100);
        result_comparator(1, 0, 0, 0, 1, 2, 0, 0, 100);

        // 시나리오 5 : set mode 상태에서 right overflow 검증
        // digit_sel=7 상태에서 btn_right 입력 시 digit_sel이 0으로 순환하는지 검증
        $strobe("SCENARIO 5");
        result_comparator(1, 0, 0, 0, 1, 3, 0, 0, 100);
        result_comparator(1, 0, 0, 0, 1, 4, 0, 0, 100);
        result_comparator(1, 0, 0, 0, 1, 5, 0, 0, 100);
        result_comparator(1, 0, 0, 0, 1, 6, 0, 0, 100);
        result_comparator(1, 0, 0, 0, 1, 7, 0, 0, 100);
        result_comparator(1, 0, 0, 0, 1, 0, 0, 0, 100);

        // 시나리오 6 : set mode 상태에서 left 버튼 검증
        // btn_left 입력 시 digit_sel이 1 감소하는지 검증
        $strobe("SCENARIO 6");
        result_comparator(1, 0, 0, 0, 1, 1, 0, 0, 100);
        result_comparator(0, 1, 0, 0, 1, 0, 0, 0, 100);

        // 시나리오 7 : set mode 상태에서 left overflow 검증
        // digit_sel=0 상태에서 btn_left 입력 시 digit_sel이 7로 순환하는지 검증
        $strobe("SCENARIO 7");
        result_comparator(0, 1, 0, 0, 1, 7, 0, 0, 100);

        // 시나리오 8 : set mode 상태에서 up 출력 검증
        // set_mode=1, btn_up=1일 때 up=1, down=0인지 검증
        $strobe("SCENARIO 8");
        result_comparator(0, 0, 1, 0, 1, 7, 1, 0, 100);

        // 시나리오 9 : set mode 상태에서 down 출력 검증
        // set_mode=1, btn_down=1일 때 down=1, up=0인지 검증
        $strobe("SCENARIO 9");
        result_comparator(0, 0, 0, 1, 1, 7, 0, 1, 100);

        // 시나리오 10 : set mode 해제 검증
        // 동작 중 set_mode=0으로 전환하면 digit_sel이 즉시 0으로 초기화되고
        // up=0, down=0이 되는지 검증
        $strobe("SCENARIO 10");
        result_comparator(0, 0, 0, 0, 0, 0, 0, 0, 100);

        // 비정상(예외/경계) 동작 시나리오 :

        // 시나리오 1 : set_mode 전환 경계 검증
        // run mode -> set mode 전환 순간, 또는 set mode -> run mode 전환 순간에
        // 버튼이 동시에 들어와도 digit_sel 초기화/유지 동작이 의도대로 수행되는지 검증
        $strobe("================================= BOUNDARY ERROR SCENARIO =================================");
        $strobe("SCENARIO 1");
        result_comparator(0, 0, 0, 0, 0, 0, 0, 0, 100); 
        result_comparator(0, 1, 0, 0, 1, 7, 0, 0, 100); // run mode -> set mode 전환 시 버튼이 눌리면 동작
        result_comparator(0, 1, 0, 0, 0, 0, 0, 0, 100); // set mode -> run mode 전환 시 버튼이 눌리면 동작 금지

        // 시나리오 2 : set mode 상태에서 right/left 동시 입력 검증
        // btn_right=1, btn_left=1 동시 입력 시 if-else 우선순위에 의해
        // right가 우선 적용되어 digit_sel이 증가하는지 검증
        $strobe("SCENARIO 2");
        result_comparator(0, 0, 0, 0, 1, 0, 0, 0, 100); // set mode, 기준 상태 0
        result_comparator(1, 1, 0, 0, 1, 1, 0, 0, 100); // right 우선이면 0 -> 1 예상

        // 시나리오 3 : set mode 상태에서 up/down 동시 입력 검증
        // btn_up=1, btn_down=1 동시 입력 시 up=1, down=1이 동시에 출력되는지 검증
        // up과 down의 우선 순위는 data path에서 결정
        $display("SCENARIO 3");
        result_comparator(0, 0, 1, 1, 1, 1, 1, 1, 100);

        // 시나리오 4 : set mode 상태에서 right/up 또는 left/down 동시 입력 검증
        // digit_sel 이동과 up/down 출력이 서로 독립적으로 정상 동작하는지 검증
        // 예: btn_right=1, btn_up=1이면 digit_sel 증가와 up=1이 동시에 성립하는지 검증
        $display("SCENARIO 4");
        result_comparator(1, 0, 1, 0, 1, 2, 1, 0, 100); // digit_sel: 1 -> 2, up=1

        // 시나리오 5 : 버튼 장입력(hold) 검증
        // btn_right 또는 btn_left를 여러 클럭 동안 유지하면 클럭마다 digit_sel이 연속 변경되는지 검증
        // (디바운스/원펄스 회로가 없으므로 현재 구조상 연속 변경이 정상 동작임)
        $display("SCENARIO 5");
        result_comparator(0, 1, 0, 1, 1, 1, 0, 1, 100); // digit_sel: 2 -> 1, down=1

        // 시나리오 6 : reset 우선 동작 검증
        // set_mode=1 또는 버튼 입력 중 rst_n=0이 들어오면 digit_sel이 0으로 초기화되는지 검증
        @(negedge clk);
        set_mode  = 1;
        btn_right = 1;
        btn_up    = 1;
        @(posedge clk);
        #1;
        $display("RESET before : digit_sel=%0d, up=%0b, down=%0b", digit_sel, up, down);

        @(negedge clk);
        rst_n     = 0;
        btn_right = 0;
        btn_up    = 0;
        @(posedge clk);
        #1;
        if ((digit_sel == 0) && (up == 0) && (down == 0))
            $display("SUCCESS %0t : reset active -> digit_sel = %0d, up = %0b, down = %0b", $time, digit_sel, up, down);
        else
            $display("FAIL %0t : reset active -> digit_sel = %0d (exp = 0), up = %0b (exp = 0), down = %0b (exp = 0)", $time, digit_sel, up, down);

        @(negedge clk);
        rst_n = 1;
        set_mode = 0;

        #100;
        $finish();
    end

endmodule
