`timescale 1ns / 1ps

interface add_interface ();
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
        $display("[%t][%s] a = %d, b = %d, mode = %d, sum = %d, carry = %d",
                 $time, name, a, b, mode, sum, carry);
    endfunction
endclass

class driver;
    transaction tr;
    mailbox #(transaction) gen2drv;
    virtual add_interface v_add_if;

    function new(virtual add_interface _v_add_if,
                 mailbox#(transaction) _gen2drv);
        this.v_add_if = _v_add_if;
        this.gen2drv  = _gen2drv;
    endfunction

    task run();
        this.gen2drv.get(tr);
        v_add_if.a = tr.a;
        v_add_if.b = tr.b;
        v_add_if.mode = tr.mode;
        tr.debug_print("DRV");
        #10;
    endtask
endclass

class generator;
    transaction tr;
    mailbox #(transaction) gen2drv;

    function new(mailbox#(transaction) _gen2drv);
        this.gen2drv = _gen2drv;
    endfunction

    task run(int cnt);
        repeat (cnt) begin
            tr = new();
            tr.randomize();
            this.gen2drv.put(tr);
            tr.debug_print("GEN");
        end
    endtask
endclass

class monitor;
    transaction tr;
    virtual add_interface v_add_if;
    mailbox #(transaction) mon2scb;

    function new(virtual add_interface _v_add_if,
                 mailbox#(transaction) _mon2scb);
        this.v_add_if = _v_add_if;
        this.mon2scb  = _mon2scb;
    endfunction

    task run();
        tr = new();
        tr.a = v_add_if.a;
        tr.b = v_add_if.b;
        tr.mode = v_add_if.mode;
        tr.sum = v_add_if.sum;
        tr.carry = v_add_if.carry;
        this.mon2scb.put(tr);
        tr.debug_print("MON");
    endtask
endclass

class scoreboard;
    transaction tr;
    mailbox #(transaction) mon2scb;

    function new(mailbox#(transaction) _mon2scb);
        this.mon2scb = _mon2scb;
    endfunction

    task run();
        this.mon2scb.get(tr);
        tr.debug_print("SCB");
    endtask
endclass

class enviroment;
    mailbox #(transaction) gen2drv;
    mailbox #(transaction) mon2scb;
    driver drv;
    generator gen;
    monitor mon;
    scoreboard scb;

    function new(virtual add_interface _v_add_if);
        this.gen2drv = new();
        this.mon2scb = new();
        this.drv = new(_v_add_if, this.gen2drv);
        this.mon = new(_v_add_if, this.mon2scb);
        this.gen = new(this.gen2drv);
        this.scb = new(this.mon2scb);
    endfunction

    task run();
        gen.run(10);
        //repeat (10) begin
            drv.run();
            mon.run();
            scb.run();
        //end
    endtask
endclass

module tb_add_sv ();
    add_interface add_if ();
    enviroment env;

    add_sv dut (
        .a    (add_if.a),
        .b    (add_if.b),
        .mode (add_if.mode),
        .sum  (add_if.sum),
        .carry(add_if.carry)
    );

    initial begin
        env = new(add_if);
        env.run();
        $finish();
    end
endmodule
