`timescale 1ns / 1ps

interface adder_interface ();
    logic [7:0] a;
    logic [7:0] b;
    logic       mode;
    logic [7:0] sum;
    logic       carry;
endinterface

class transaction;
    rand bit [7:0] a;
    rand bit [7:0] b;
    rand bit       mode;
    bit      [7:0] sum;
    bit            carry;

    function debug_print(string name);
        $display("%t : [%s] a = %d, b = %d, mode = %d, sum = %d, carry = %d", $time, name, a, b,
                 mode, sum, carry);
    endfunction

    // constraint in_range {
    //     a>128;
    //     b>250;
    // }

    constraint in_range {
        a inside {[0:127]};
    }

    constraint in_distribute {
        mode dist {0:/80, 1:/20};
    }

    constraint in_b {
        if(mode == 0) { 
            b inside {0,1,2,3,15,31,250};
        } else {
            b > 128;
        }
    }

endclass

class generator;
    transaction tr;
    mailbox #(transaction) gen2drv_mbox;
    event event_gen_next;

    function new(mailbox#(transaction) _gen2drv_mbox, event _event_gen_next);
        this.gen2drv_mbox = _gen2drv_mbox;
        this.event_gen_next = _event_gen_next;
    endfunction

    task run();
        repeat(10) begin
            tr = new();  // 왜 생성 후 사용?
            tr.randomize();
            this.gen2drv_mbox.put(tr);
            tr.debug_print("GEN");
            @(event_gen_next);
        end
    endtask
endclass

class driver;
    transaction tr;
    virtual adder_interface adder_vif;
    mailbox #(transaction) gen2drv_mbox;
    event event_gen_next;
    event event_drv_next;

    function new(mailbox#(transaction) _gen2drv_mbox,
                 virtual adder_interface _adder_vinterf,
                 event _event_gen_next);
        this.adder_vif = _adder_vinterf;
        this.gen2drv_mbox = _gen2drv_mbox;
        this.event_gen_next = _event_gen_next;
    endfunction

    task run();
        forever begin
            this.gen2drv_mbox.get(tr);
            adder_vif.a = tr.a;
            adder_vif.b = tr.b;
            adder_vif.mode = tr.mode;
            tr.debug_print("DRV");
            #10;
            -> event_gen_next;
            $display("DRV task end");
        end
    endtask

endclass

class monitor;
    transaction tr;
    virtual adder_interface adder_vif;
    mailbox #(transaction) mon2score_mbox;
    event event_mon_next;

    function new(mailbox#(transaction) _mon2score_mbox,
                 virtual adder_interface _adder_vif,
                 event _event_mon_next);
        this.adder_vif = _adder_vif;
        this.mon2score_mbox = _mon2score_mbox;
        this.event_mon_next = _event_mon_next;
    endfunction

    task run();
        forever begin
            #5;
            tr = new;
            tr.a = adder_vif.a;
            tr.b = adder_vif.b;
            tr.mode = adder_vif.mode;
            tr.sum = adder_vif.sum;
            tr.carry = adder_vif.carry;
            mon2score_mbox.put(tr);
            tr.debug_print("MON");
            #5;
            //@(event_mon_next);
        end
    endtask
endclass

class scoreboard;
    transaction tr;
    mailbox #(transaction) mon2score_mbox;
    event event_mon_next;
    
    int pass_cnt = 0, fail_cnt = 0, total_cnt = 0;

    function new(mailbox#(transaction) _mon2score_mbox, event _event_mon_next);
        this.mon2score_mbox = _mon2score_mbox;
        this.event_mon_next = _event_mon_next;
    endfunction

    task run();
        logic [7:0] expected_sum;
        logic expected_carry;

        forever begin
            mon2score_mbox.get(tr);
            tr.debug_print("SCB");
            //-> event_mon_next;
            if(tr.mode) begin
                {expected_carry,expected_sum} = tr.a - tr.b;
            end else begin
                {expected_carry,expected_sum} = tr.a + tr.b;
            end
            if((tr.sum == expected_sum) && (tr.carry == expected_carry)) begin
                $display("[%t][PASS]", $time);
                pass_cnt = pass_cnt + 1;
            end else begin
                $display("[%t][FAIL] a = %d, b = %d, mode = %d, sum = %d, carry = %d", $time, tr.a, tr.b, tr.mode, tr.sum, tr.carry);
                fail_cnt = fail_cnt + 1;
            end
            total_cnt = total_cnt + 1;
        end
    endtask
endclass

class environment;
    generator gen;
    driver drv;
    monitor mon;
    scoreboard scb;
    mailbox #(transaction) gen2drv_mbox;
    mailbox #(transaction) mon2score_mbox;

    event event_gen_next;
    event event_drv_next;
    event event_mon_next;
    event event_scb_next;


    function new(virtual adder_interface _adder_vif);
        this.gen2drv_mbox = new();
        this.mon2score_mbox = new();
        gen = new(this.gen2drv_mbox, event_gen_next);
        drv = new(this.gen2drv_mbox, _adder_vif, event_gen_next);
        mon = new(this.mon2score_mbox, _adder_vif, event_mon_next);
        scb = new(this.mon2score_mbox, event_mon_next);
    endfunction

    task run();
        fork
            drv.run();
            gen.run();
            mon.run();
            scb.run();
        join_any
        $display("ENV fork join end");
        $display("[%t]TOTAL = %d", $time, scb.total_cnt);
        $display("[%t]PASS  = %d", $time, scb.pass_cnt);
        $display("[%t]FAIL  = %d", $time, scb.fail_cnt);
    endtask
endclass

module tb_alu_sv ();
    adder_interface adder_if ();
    environment env;

    adder_sv u1_adder_sv (
        .a    (adder_if.a),
        .b    (adder_if.b),
        .mode (adder_if.mode),
        .sum  (adder_if.sum),
        .carry(adder_if.carry)
    );

    initial begin
        env = new(adder_if);
        env.run();
        $stop();
    end
endmodule
