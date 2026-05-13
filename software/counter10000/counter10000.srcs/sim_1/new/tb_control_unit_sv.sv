`timescale 1ns / 1ps

interface control_unit_interface ();
    logic clk;
    logic rst_n;

    logic btn_run;
    logic btn_clear;
    logic btn_mode;

    logic run;
    logic clear;
    logic mode;
endinterface

class transaction;
    bit clk;
    bit rst_n;

    rand bit btn_run;
    rand bit btn_clear;
    rand bit btn_mode;

    rand int debug_delay;

    bit run;
    bit clear;
    bit mode;

    task debug_print(string name);
        $display(
            "[%t][%s] btn_run = %d, btn_clear = %d, btn_mode = %d, run = %d, clear = %d, mode = %d",
            $time, name, btn_run, btn_clear, btn_mode, run, clear, mode);
    endtask

    constraint in_delay {debug_delay inside {[1 : 3]};}

    constraint in_clear {
        btn_clear dist {
            0 :/ 90,
            1 :/ 10
        };
    }
endclass

class generator;
    transaction tr;
    mailbox #(transaction) gen2drv_mbox;
    event event_drv2gen;

    function new(mailbox#(transaction) _gen2drv_mbox, event _event_drv2gen);
        this.gen2drv_mbox = _gen2drv_mbox;
        event_drv2gen = _event_drv2gen;
    endfunction

    task run(int cnt);
        repeat (cnt) begin
            tr = new();
            tr.randomize();
            gen2drv_mbox.put(tr);
            tr.debug_print("GEN");
            @(event_drv2gen);
        end
    endtask
endclass

class driver;
    transaction tr;
    mailbox #(transaction) gen2drv_mbox;
    virtual control_unit_interface v_control_unit_if;
    event event_drv2gen;

    function new(mailbox#(transaction) _gen2drv_mbox,
                 virtual control_unit_interface _v_control_unit_if,
                 event _event_drv2gen);
        this.gen2drv_mbox = _gen2drv_mbox;
        this.v_control_unit_if = _v_control_unit_if;
        event_drv2gen = _event_drv2gen;
    endfunction

    task run();
        forever begin
            gen2drv_mbox.get(tr);
            @(negedge v_control_unit_if.clk);
            v_control_unit_if.btn_run   = tr.btn_run;
            v_control_unit_if.btn_clear = tr.btn_clear;
            v_control_unit_if.btn_mode  = tr.btn_mode;
            @(posedge v_control_unit_if.clk);
            @(negedge v_control_unit_if.clk);
            v_control_unit_if.btn_run   = 0;
            v_control_unit_if.btn_clear = 0;
            v_control_unit_if.btn_mode  = 0;
            tr.debug_print("DRV");
            #(tr.debug_delay * 1000_000);
            ->event_drv2gen;
        end
    endtask

    task reset();
        @(negedge v_control_unit_if.clk);
        v_control_unit_if.rst_n     = 0;
        v_control_unit_if.btn_run   = 0;
        v_control_unit_if.btn_clear = 0;
        v_control_unit_if.btn_mode  = 0;
        @(posedge v_control_unit_if.clk);
        #1000_000;
        v_control_unit_if.rst_n = 1;
    endtask
endclass

class monitor;
    transaction tr;
    mailbox #(transaction) mon2scb_mbox;
    virtual control_unit_interface v_control_unit_if;

    function new(mailbox#(transaction) _mon2scb_mbox,
                 virtual control_unit_interface _v_control_unit_if);
        this.mon2scb_mbox = _mon2scb_mbox;
        this.v_control_unit_if = _v_control_unit_if;
    endfunction

    task run();
        forever begin
            @(posedge v_control_unit_if.clk);
            #1;
            tr           = new();
            tr.btn_run   = v_control_unit_if.btn_run;
            tr.btn_clear = v_control_unit_if.btn_clear;
            tr.btn_mode  = v_control_unit_if.btn_mode;
            tr.run       = v_control_unit_if.run;
            tr.clear     = v_control_unit_if.clear;
            tr.mode      = v_control_unit_if.mode;
            mon2scb_mbox.put(tr);
            //tr.debug_print("MON");
        end
    endtask
endclass

class scoreboard;
    transaction tr;
    mailbox #(transaction) mon2scb_mbox;

    int total_cnt = 0, pass_cnt = 0, fail_cnt = 0;

    bit exp_run_q = 0;
    bit exp_clear_q = 0;
    bit exp_mode_q = 0;

    bit next_run;
    bit next_clear;
    bit next_mode;

    function new(mailbox#(transaction) _mon2scb_mbox);
        this.mon2scb_mbox = _mon2scb_mbox;
    endfunction

    task compare(transaction tr);
        bit next_run;
        bit next_clear;
        bit next_mode;

        begin
            if ((tr.run   == exp_run_q) &&
            (tr.clear == exp_clear_q) &&
            (tr.mode  == exp_mode_q)) begin
                $display("[%t][PASS]", $time);
                pass_cnt++;
            end else begin
                $display(
                    "[%t][FAIL] actual_run=%0d actual_clear=%0d actual_mode=%0d",
                    $time, tr.run, tr.clear, tr.mode);
                $display(
                    "[%t][    ] expect_run=%0d expect_clear=%0d expect_mode=%0d",
                    $time, exp_run_q, exp_clear_q, exp_mode_q);
                fail_cnt++;
            end

            total_cnt++;

            next_run   = exp_run_q;
            next_clear = 1'b0;
            next_mode  = exp_mode_q;

            if (tr.btn_clear && !exp_run_q) begin
                next_clear = 1'b1;
            end else if (tr.btn_mode && !exp_run_q) begin
                next_mode = ~exp_mode_q;
            end else if (tr.btn_run) begin
                next_run = ~exp_run_q;
            end

            exp_run_q   = next_run;
            exp_clear_q = next_clear;
            exp_mode_q  = next_mode;
        end
    endtask

    task run();
        forever begin
            mon2scb_mbox.get(tr);
            compare(tr);
            tr.debug_print("SCB");
        end
    endtask
endclass

class environment;
    generator gen;
    driver drv;
    monitor mon;
    scoreboard scb;
    mailbox #(transaction) gen2drv_mbox;
    mailbox #(transaction) mon2scb_mbox;
    event event_drv2gen;

    function new(virtual control_unit_interface _v_control_unit_if);
        gen2drv_mbox = new();
        mon2scb_mbox = new();
        gen = new(gen2drv_mbox, event_drv2gen);
        drv = new(gen2drv_mbox, _v_control_unit_if, event_drv2gen);
        mon = new(mon2scb_mbox, _v_control_unit_if);
        scb = new(mon2scb_mbox);
    endfunction

    task run();
        drv.reset();
        fork
            gen.run(100);
            drv.run();
            mon.run();
            scb.run();
        join_any

        $display("=========================================");
        $display("total_cnt = %d", scb.total_cnt);
        $display("pass_cnt  = %d", scb.pass_cnt);
        $display("fail_cnt  = %d", scb.fail_cnt);
        $display("=========================================");


        #100;
        $stop;
    endtask
endclass

module tb_control_unit_sv ();
    control_unit_interface control_unit_if ();
    environment env;

    control_unit dut (
        .clk      (control_unit_if.clk),
        .rst_n    (control_unit_if.rst_n),      // active low reset
        .btn_run  (control_unit_if.btn_run),
        .btn_clear(control_unit_if.btn_clear),
        .btn_mode (control_unit_if.btn_mode),
        .run      (control_unit_if.run),
        .clear    (control_unit_if.clear),
        .mode     (control_unit_if.mode)
    );

    always #5 control_unit_if.clk = ~control_unit_if.clk;

    initial begin
        control_unit_if.clk = 0;
        env = new(control_unit_if);
        env.run();
    end

endmodule
