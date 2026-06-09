`timescale 1ns / 1ps

interface btn_debounce_interface ();
    logic clk;
    logic rst_n;
    logic btn_in;
    logic btn_pulse;
endinterface

class transaction;
    bit rst_n;
    bit btn_in;
    bit btn_pulse;
    rand int press_time;
    rand int bounce_count;

    constraint c_press {press_time inside {[4 : 6]};}

    constraint c_bounce {bounce_count inside {[1 : 7]};}

    task debug_print(string name);
        begin
            $display("[%s][%t] btn_in = %d, btn_pulse = %b", name, $time,
                     btn_in, btn_pulse);
        end
    endtask
endclass

class generator;
    transaction tr;
    mailbox #(transaction) gen2drv_mbox;
    event event_drv2gen;

    function new(mailbox#(transaction) _gen2drv_mbox, 
        event _event_drv2gen);
        this.gen2drv_mbox = _gen2drv_mbox;
        event_drv2gen = _event_drv2gen;
    endfunction

    task run(int cnt);
        repeat (cnt) begin
            tr = new();
            tr.randomize();
            this.gen2drv_mbox.put(tr);
            tr.debug_print("GEN");
            @(event_drv2gen);
        end
    endtask
endclass

class driver;
    transaction tr;
    mailbox #(transaction) gen2drv_mbox;
    virtual btn_debounce_interface v_btn_debounce_if;
    event event_drv2gen;

    function new(virtual btn_debounce_interface _v_btn_debounce_if,
                 mailbox#(transaction) _gen2drv_mbox, event _event_drv2gen);
        this.v_btn_debounce_if = _v_btn_debounce_if;
        this.gen2drv_mbox = _gen2drv_mbox;
        this.event_drv2gen = _event_drv2gen;
    endfunction

    task reset_n();
        @(posedge v_btn_debounce_if.clk);
        v_btn_debounce_if.rst_n  = 1'b0;
        v_btn_debounce_if.btn_in = 0;
        #1000_000;
        v_btn_debounce_if.rst_n = 1'b1;
    endtask

    task run();
        forever begin
            gen2drv_mbox.get(tr);
            // bounce
            repeat (tr.bounce_count) begin
                @(negedge v_btn_debounce_if.clk);
                v_btn_debounce_if.btn_in = ~v_btn_debounce_if.btn_in;

                repeat (10_000) @(posedge v_btn_debounce_if.clk);
            end
            // stable press
            @(negedge v_btn_debounce_if.clk);
            v_btn_debounce_if.btn_in = 1'b1;
            repeat (tr.press_time * 100_000) @(posedge v_btn_debounce_if.clk);
            // release
            @(negedge v_btn_debounce_if.clk);
            v_btn_debounce_if.btn_in = 1'b0;
            repeat (500_000) @(posedge v_btn_debounce_if.clk);
            ->event_drv2gen;
        end
    endtask
endclass

class monitor;
    transaction tr;
    mailbox #(transaction) mon2scb_mbox;
    virtual btn_debounce_interface v_btn_debounce_if;

    function new(virtual btn_debounce_interface _v_btn_debounce_if,
                 mailbox#(transaction) _mon2scb_mbox);
        this.v_btn_debounce_if = _v_btn_debounce_if;
        this.mon2scb_mbox = _mon2scb_mbox;
    endfunction

    task run();
        forever begin
            @(negedge v_btn_debounce_if.clk);
            this.tr = new();
            this.tr.btn_in = this.v_btn_debounce_if.btn_in;
            this.tr.btn_pulse = this.v_btn_debounce_if.btn_pulse;
            this.mon2scb_mbox.put(tr);
            //tr.debug_print("MON");
        end
    endtask
endclass

class scoreboard;
    transaction tr;
    mailbox #(transaction) mon2scb_mbox;

    function new(mailbox#(transaction) _mon2scb_mbox);
        this.mon2scb_mbox = _mon2scb_mbox;
    endfunction

    int total_cnt = 0, pass_cnt = 0, fail_cnt = 0;
    logic [$clog2(100_000_000)-1:0] count;
    logic [5:0] shift_reg = 0;

    task compare(logic actual_btn_in, logic actual_btn_pulse);
        shift_reg = {shift_reg[4:0], actual_btn_in};

        if (shift_reg[5]) begin
            count++;
            if (count > 499_990 && count < 500_010) begin
                $display("[%t][scope][count = %d] btn_in = %d, btn_pulse = %d",
                         $time, count, actual_btn_in, actual_btn_pulse);
            end
            if (count == 500_000 - 1) begin
                total_cnt++;
                if (actual_btn_pulse) begin
                    $display("[%t][PASS]", $time);
                    pass_cnt++;
                end else begin
                    $display(
                        "[%t][FAIL][count = %d] btn_in = %d, btn_pulse = %d",
                        $time, count, actual_btn_in, actual_btn_pulse);
                    fail_cnt++;
                end
            end
        end else begin
            count = 0;
        end
    endtask

    task run();
        forever begin
            this.mon2scb_mbox.get(tr);
            //this.tr.debug_print("SCB");
            compare(tr.btn_in, tr.btn_pulse);
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

    function new(virtual btn_debounce_interface _v_btn_debounce_if);
        gen2drv_mbox = new();
        mon2scb_mbox = new();
        gen = new(this.gen2drv_mbox, this.event_drv2gen);
        drv = new(_v_btn_debounce_if, this.gen2drv_mbox, this.event_drv2gen);
        mon = new(_v_btn_debounce_if, this.mon2scb_mbox);
        scb = new(this.mon2scb_mbox);
    endfunction

    task run();
        drv.reset_n();
        fork
            gen.run(10);
            drv.run();
            mon.run();
            scb.run();
        join_any

        $display("=========================================================");
        $display("[total_cnt] %d ", scb.total_cnt);
        $display("[pass_cnt] %d ", scb.pass_cnt);
        $display("[fail_cnt] %d ", scb.fail_cnt);
        $display("=========================================================");

        disable fork;
        $stop;
    endtask
endclass

module tb_debounce_sv ();
    btn_debounce_interface btn_debounce_if ();
    environment env;

    btn_interface #(
        .CLK_FREQ_HZ(100_000_000),
        .DEBOUNCE_MS(5)
    ) dut (
        .clk(btn_debounce_if.clk),
        .rst_n(btn_debounce_if.rst_n),
        .btn_in(btn_debounce_if.btn_in),
        .btn_pulse(btn_debounce_if.btn_pulse)
    );

    always #5 btn_debounce_if.clk = ~btn_debounce_if.clk;

    initial begin
        btn_debounce_if.clk = 1'b0;
        env = new(btn_debounce_if);
        env.run();
    end
endmodule
