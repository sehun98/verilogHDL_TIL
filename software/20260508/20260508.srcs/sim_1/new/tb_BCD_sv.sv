`timescale 1ns / 1ps

interface BCD_interface();
    logic [3:0] data;
    logic [7:0] seg;
endinterface

class transaction;
    rand bit [3:0] data;
    bit [7:0] seg;

    task debug_print(string name);
        $display("[%s][%t] data = %b, seg = %b", name, $time, data, seg);
    endtask
endclass

class generator;
    transaction tr;
    mailbox #(transaction) gen2drv_mbox;

    function new(mailbox#(transaction) _gen2drv_mbox);
        this.gen2drv_mbox = _gen2drv_mbox;
    endfunction

    task run();
        tr = new();
        tr.randomize();
        this.gen2drv_mbox.put(tr);
        tr.debug_print("GEN");
    endtask
endclass

class driver;
    transaction tr;
    virtual BCD_interface v_BCD_if;
    mailbox #(transaction) gen2drv_mbox;

    function new(virtual BCD_interface _v_BCD_if,
                 mailbox#(transaction) _gen2drv_mbox);
        this.gen2drv_mbox = _gen2drv_mbox;
        this.v_BCD_if = _v_BCD_if;
    endfunction

    task run();
        this.gen2drv_mbox.get(tr);
        v_BCD_if.data = tr.data;
        tr.debug_print("DRV");
        #10;
    endtask
endclass

class monitor;
    transaction tr;
    virtual BCD_interface v_BCD_if;
    mailbox #(transaction) mon2scb_mbox;

    function new(virtual BCD_interface _v_BCD_if,
                 mailbox#(transaction) _mon2scb_mbox);
        this.mon2scb_mbox = _mon2scb_mbox;
        this.v_BCD_if = _v_BCD_if;
    endfunction

    task run();
        tr = new();
        tr.data = v_BCD_if.data;
        tr.seg = v_BCD_if.seg;
        this.mon2scb_mbox.put(tr);
        tr.debug_print("MON");
    endtask
endclass

class scoreboard;
    transaction tr;
    mailbox #(transaction) mon2scb_mbox;

    function new(mailbox#(transaction) _mon2scb_mbox);
        this.mon2scb_mbox = _mon2scb_mbox;
    endfunction

    task run();
        this.mon2scb_mbox.get(tr);
        tr.debug_print("SCB");
    endtask

endclass

class environment;
    mailbox #(transaction) gen2drv_mbox;
    mailbox #(transaction) mon2scb_mbox;
    generator gen;
    driver drv;
    monitor mon;
    scoreboard scb;

    function new(virtual BCD_interface _v_BCD_if);
        this.gen2drv_mbox = new();
        this.mon2scb_mbox = new();
        this.gen = new(this.gen2drv_mbox);
        this.drv = new(_v_BCD_if, this.gen2drv_mbox);
        this.mon = new(_v_BCD_if, this.mon2scb_mbox);
        this.scb = new(this.mon2scb_mbox);
    endfunction

    task run();
        repeat (10) begin
            gen.run();
            drv.run();
            mon.run();
            scb.run();
        end
    endtask

endclass

module tb_BCD_sv ();
    BCD_interface BCD_if();
    environment   env;

    BCD_sv dut (
        .data(BCD_if.data),
        .seg (BCD_if.seg)
    );

    initial begin
        env = new(BCD_if);
        env.run();
        $finish();
    end
endmodule
