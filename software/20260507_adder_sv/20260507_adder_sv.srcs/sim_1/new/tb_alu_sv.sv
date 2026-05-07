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
endclass

class generator;
    transaction tr;
    mailbox #(transaction) gen2drv_mbox;

    function new(mailbox#(transaction) _gen2drv_mbox);
        this.gen2drv_mbox = _gen2drv_mbox;
    endfunction

    task run(int cnt);
        repeat (cnt) begin
            tr = new();  // 왜 생성 후 사용?
            tr.randomize();
            this.gen2drv_mbox.put(tr);
            tr.debug_print("GEN");
        end
    endtask
endclass

class driver;
    transaction tr;
    virtual adder_interface adder_vif;
    mailbox #(transaction) gen2drv_mbox;

    function new(mailbox#(transaction) _gen2drv_mbox,
                 virtual adder_interface _adder_vinterf);
        this.adder_vif = _adder_vinterf;
        this.gen2drv_mbox = _gen2drv_mbox;
    endfunction

    task run();
        this.gen2drv_mbox.get(tr);
        adder_vif.a = tr.a;
        adder_vif.b = tr.b;
        adder_vif.mode = tr.mode;
        tr.debug_print("DRV");
        #10;
    endtask
endclass

class monitor;
    transaction tr;
    virtual adder_interface adder_vif;
    mailbox #(transaction) mon2score_mbox;

    function new(mailbox#(transaction) _mon2score_mbox,
                 virtual adder_interface _adder_vif);
        this.adder_vif = _adder_vif;
        this.mon2score_mbox = _mon2score_mbox;
    endfunction

    task run();
        tr = new;
        tr.a = adder_vif.a;
        tr.b = adder_vif.b;
        tr.mode = adder_vif.mode;
        tr.sum = adder_vif.sum;
        tr.carry = adder_vif.carry;
        mon2score_mbox.put(tr);
        tr.debug_print("MON");
    endtask
endclass

class scoreboard;
    transaction tr;
    mailbox #(transaction) mon2score_mbox;
    function new(mailbox#(transaction) _mon2score_mbox);
        this.mon2score_mbox = _mon2score_mbox;
    endfunction

    task run();
        mon2score_mbox.get(tr);
        tr.debug_print("SCB");
    endtask
endclass

class environment;
    generator gen;
    driver drv;
    monitor mon;
    scoreboard scb;
    mailbox #(transaction) gen2drv_mbox;
    mailbox #(transaction) mon2score_mbox;

    function new(virtual adder_interface _adder_vif);
        this.gen2drv_mbox = new();
        this.mon2score_mbox = new();
        gen = new(this.gen2drv_mbox);
        drv = new(this.gen2drv_mbox, _adder_vif);
        mon = new(this.mon2score_mbox, _adder_vif);
        scb = new(this.mon2score_mbox);
    endfunction

    task run();
        gen.run(10);
        forever begin
            drv.run();
            mon.run();
            scb.run();
        end
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
