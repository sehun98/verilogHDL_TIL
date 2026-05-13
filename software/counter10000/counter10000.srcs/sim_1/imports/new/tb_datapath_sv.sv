`timescale 1ns / 1ps

interface datapath_interface ();
    logic clk;
    logic rst_n;

    logic run;
    logic clear;
    logic mode;

    logic [13:0] tick_count;
endinterface

class transaction;
    bit clk;
    bit rst_n;

    rand bit run;
    rand bit clear;
    rand bit mode;

    rand int debug_delay;
    bit [13:0] tick_count;

    constraint in_debug_delay {
        //debug_delay inside {[10:20]};
        debug_delay inside {[1 : 2]};
    }

    constraint in_clear {
        clear dist {
            0 :/ 90,
            1 :/ 10
        };
    }

    task debug_print(string name);
        $display(
            "[%t][%s] run = %d, clear = %d, mode = %d, tick_count =%d, debug_delay = %d",
            $time, name, run, clear, mode, tick_count, debug_delay);
    endtask
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
    virtual datapath_interface v_datapath_if;
    event event_drv2gen;

    function new(mailbox#(transaction) _gen2drv_mbox,
                 virtual datapath_interface _v_datapath_if,
                 event _event_drv2gen);
        this.gen2drv_mbox = _gen2drv_mbox;
        this.v_datapath_if = _v_datapath_if;
        event_drv2gen = _event_drv2gen;
    endfunction

    task run();
        forever begin
            gen2drv_mbox.get(tr);

            @(negedge v_datapath_if.clk);

            v_datapath_if.run   = tr.run;
            v_datapath_if.mode  = tr.mode;
            v_datapath_if.clear = tr.clear;

            @(negedge v_datapath_if.clk);
            v_datapath_if.clear = 1'b0;

            tr.debug_print("DRV");

            #(tr.debug_delay * 10_000_0);  //10_000_000 100ms 단위 대기, 2ms

            ->event_drv2gen;
        end
    endtask

    task reset();
        v_datapath_if.clk = 0;
        @(negedge v_datapath_if.clk);
        v_datapath_if.rst_n = 0;
        v_datapath_if.run   = 0;
        v_datapath_if.clear = 0;
        v_datapath_if.mode  = 0;
        @(posedge v_datapath_if.clk);
        #1000_000;
        v_datapath_if.rst_n = 1;
    endtask
endclass

class monitor;
    transaction tr;
    mailbox #(transaction) mon2scb_mbox;
    virtual datapath_interface v_datapath_if;

    function new(mailbox#(transaction) _mon2scb_mbox,
                 virtual datapath_interface _v_datapath_if);
        this.mon2scb_mbox  = _mon2scb_mbox;
        this.v_datapath_if = _v_datapath_if;
    endfunction

    task run();
        forever begin
            @(posedge v_datapath_if.clk);
            #1;
            tr            = new();
            tr.rst_n      = v_datapath_if.rst_n;
            tr.run        = v_datapath_if.run;
            tr.clear      = v_datapath_if.clear;
            tr.mode       = v_datapath_if.mode;
            tr.tick_count = v_datapath_if.tick_count;
            mon2scb_mbox.put(tr);
            //tr.debug_print("MON");
        end
    endtask
endclass

class scoreboard;
    transaction tr;
    mailbox #(transaction) mon2scb_mbox;

    localparam int TICK_MAX = 10_000;
    localparam int TICK_COUNT = 10_000;

    int        total_cnt           = 0;
    int        pass_cnt            = 0;
    int        fail_cnt            = 0;

    bit        exp_tick_10hz;
    bit        prev_exp_tick_10hz;
    int        tick_gen_cnt;
    bit [13:0] exp_tick_count;

    function new(mailbox#(transaction) _mon2scb_mbox);
        this.mon2scb_mbox       = _mon2scb_mbox;
        this.exp_tick_10hz      = 1'b0;
        this.prev_exp_tick_10hz = 1'b0;
        this.tick_gen_cnt       = 0;
        this.exp_tick_count     = 14'd0;
    endfunction

    task compare(transaction tr);
        begin
            total_cnt++;
            exp_tick_10hz = 1'b0;

            if (!tr.rst_n) begin
                tick_gen_cnt       = 0;
                exp_tick_10hz      = 1'b0;
                prev_exp_tick_10hz = 1'b0;
                exp_tick_count     = 14'd0;
            end else begin
                if (tr.clear) begin
                    exp_tick_count = 14'd0;
                end else if (prev_exp_tick_10hz && tr.run) begin
                    if (!tr.mode) begin
                        if (exp_tick_count == TICK_COUNT - 1) begin
                            exp_tick_count = 14'd0;
                        end else begin
                            exp_tick_count = exp_tick_count + 14'd1;
                        end
                    end else begin
                        if (exp_tick_count == 0) begin
                            exp_tick_count = TICK_COUNT - 1;
                        end else begin
                            exp_tick_count = exp_tick_count - 14'd1;
                        end
                    end
                end
                if (tick_gen_cnt == TICK_MAX - 1) begin
                    tick_gen_cnt  = 0;
                    exp_tick_10hz = 1'b1;
                end else begin
                    tick_gen_cnt  = tick_gen_cnt + 1;
                    exp_tick_10hz = 1'b0;
                end
                prev_exp_tick_10hz = exp_tick_10hz;
            end

            if (tr.tick_count === exp_tick_count) begin
                pass_cnt++;
                $display(
                    "[%0t][PASS] rst_n=%0b run=%0b clear=%0b mode=%0b exp_tick_10hz=%0b tick_gen_cnt=%0d | exp_tick_count=%0d tick_count=%0d",
                    $time, tr.rst_n, tr.run, tr.clear, tr.mode, exp_tick_10hz,
                    tick_gen_cnt, exp_tick_count, tr.tick_count);
            end else begin
                fail_cnt++;
                $display(
                    "[%0t][FAIL] rst_n=%0b run=%0b clear=%0b mode=%0b exp_tick_10hz=%0b tick_gen_cnt=%0d | exp_tick_count=%0d tick_count=%0d",
                    $time, tr.rst_n, tr.run, tr.clear, tr.mode, exp_tick_10hz,
                    tick_gen_cnt, exp_tick_count, tr.tick_count);
            end
        end
    endtask

    task run();
        forever begin
            mon2scb_mbox.get(tr);
            compare(tr);
        end
    endtask
endclass

class environment;
    transaction tr;
    generator gen;
    driver drv;
    monitor mon;
    scoreboard scb;
    mailbox #(transaction) gen2drv_mbox;
    mailbox #(transaction) mon2scb_mbox;
    event event_drv2gen;

    function new(virtual datapath_interface _v_datapath_if);
        gen2drv_mbox = new();
        mon2scb_mbox = new();
        gen = new(gen2drv_mbox, event_drv2gen);
        drv = new(gen2drv_mbox, _v_datapath_if, event_drv2gen);
        mon = new(mon2scb_mbox, _v_datapath_if);
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

module tb_datapath_sv ();
    datapath_interface datapath_if ();
    environment env;

    data_path dut (
        .clk       (datapath_if.clk),
        .rst_n     (datapath_if.rst_n),
        .run       (datapath_if.run),
        .clear     (datapath_if.clear),
        .mode      (datapath_if.mode),
        .tick_count(datapath_if.tick_count)
    );

    always #5 datapath_if.clk = ~datapath_if.clk;

    initial begin
        env = new(datapath_if);
        env.run();
    end
endmodule
