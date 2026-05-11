`timescale 1ns / 1ps

interface btn_debounce_interface ();
    logic clk;
    logic rst_n;
    logic din;
    logic dout;
endinterface

class transaction;
    bit rst_n;
    rand bit din;
    bit dout;
    rand int press_time;
    rand int bounce_count;

    constraint c_press {press_time inside {[1 : 50]};}

    constraint c_bounce {bounce_count inside {[0 : 5]};}

    task debug_print(string name);
        begin
            $display("[%s][%t] din = %d, dout = %b", name, $time, din, dout);
        end
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
        v_btn_debounce_if.rst_n = 1'b0;
        v_btn_debounce_if.din   = 0;
        repeat (10) @(posedge v_btn_debounce_if.clk);
        v_btn_debounce_if.rst_n = 1'b1;
    endtask

    task run();
        forever begin
            gen2drv_mbox.get(tr);

            // bounce 발생
            repeat (tr.bounce_count) begin
                v_btn_debounce_if.din = ~v_btn_debounce_if.din;
                #(100_000);  // 0.1ms
            end

            // 정상 press 유지
            v_btn_debounce_if.din = 1'b1;
            #(tr.press_time * 1_000_000);

            // release
            v_btn_debounce_if.din = 1'b0;
            #5_000_000;

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
            @(posedge v_btn_debounce_if.clk);
            this.tr = new();
            this.tr.din = this.v_btn_debounce_if.din;
            this.tr.dout = this.v_btn_debounce_if.dout;
            this.mon2scb_mbox.put(tr);
            tr.debug_print("MON");
        end
    endtask
endclass

class scoreboard;
    transaction tr;
    mailbox #(transaction) mon2scb_mbox;

    function new(mailbox#(transaction) _mon2scb_mbox);
        this.mon2scb_mbox = _mon2scb_mbox;
    endfunction

    task run();
        forever begin
            this.mon2scb_mbox.get(tr);
            this.tr.debug_print("SCB");
            //compare(tr.data, tr.digit, tr.seg);
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
        /*
        $display("=========================================================");
        $display("[total_cnt] %d ", scb.total_cnt);
        $display("[pass_cnt] %d ", scb.pass_cnt);
        $display("[fail_cnt] %d ", scb.fail_cnt);
        $display("=========================================================");
*/
        disable fork;
        $stop;
    endtask
endclass

module tb_debounce_sv ();
    btn_debounce_interface btn_debounce_if ();
    environment env;

    debounce #(
        .CLK_FREQ_HZ(100_000_000),
        .DEBOUNCE_MS(20)
    ) dut (
        .clk  (btn_debounce_if.clk),
        .rst_n(btn_debounce_if.rst_n),
        .din  (btn_debounce_if.din),
        .dout (btn_debounce_if.dout)
    );

    always #5 btn_debounce_if.clk = ~btn_debounce_if.clk;

    initial begin
        btn_debounce_if.clk = 1'b0;
        env = new(btn_debounce_if);
        env.run();
    end
endmodule
