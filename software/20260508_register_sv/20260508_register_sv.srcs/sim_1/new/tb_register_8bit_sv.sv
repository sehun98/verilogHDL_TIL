`timescale 1ns / 1ps
// sram
//32bit data bus
class transaction;
    rand bit [7:0] d;
    bit      [7:0] q;

    task debug_print(string name);
        $display("%s", name);
    endtask
endclass

interface register_interface ();
    logic       clk;
    logic       rst_n;
    logic [7:0] d;
    logic [7:0] q;
endinterface

class generator;
    transaction tr;
    mailbox #(transaction) gen2drv_mbox;
    event scb2gen_event_next;

    function new(mailbox#(transaction) _gen2drv_mbox,
                 event _scb2gen_event_next);
        this.gen2drv_mbox = _gen2drv_mbox;
        this.scb2gen_event_next = _scb2gen_event_next;
    endfunction

    task run();
        repeat(10) begin
            tr = new();
            tr.randomize();
            this.gen2drv_mbox.put(tr);
            tr.debug_print("GEN");
            @(scb2gen_event_next);
        end
    endtask

endclass

class driver;
    transaction tr;
    mailbox #(transaction) gen2drv_mbox;
    virtual register_interface v_register_if;
    event drv2mon_event_next;

    function new(virtual register_interface _v_register_if,
                 mailbox#(transaction) _gen2drv_mbox,
                 event _drv2mon_event_next);
        this.v_register_if = _v_register_if;
        this.gen2drv_mbox = _gen2drv_mbox;
        this.drv2mon_event_next = _drv2mon_event_next;
    endfunction

    task reset_n();
        v_register_if.rst_n = 1'b0;
        repeat(2) @(posedge v_register_if.clk);
        v_register_if.rst_n = 1'b1;
    endtask

    task run();
        forever begin
            @(posedge v_register_if.clk);
            #1;
            this.gen2drv_mbox.get(tr);
            this.v_register_if.d = tr.d;
            tr.debug_print("DRV");
            @(negedge v_register_if.clk);
            -> drv2mon_event_next;
        end
    endtask

endclass

class monitor;
    transaction tr;
    mailbox #(transaction) mon2scb_mbox;
    virtual register_interface v_register_if;
    event drv2mon_event_next;

    function new(virtual register_interface _v_register_if,
                 mailbox#(transaction) _mon2scb_mbox,
                 event _drv2mon_event_next);
        this.v_register_if = _v_register_if;
        this.mon2scb_mbox = _mon2scb_mbox;
        this.drv2mon_event_next = _drv2mon_event_next;
    endfunction

    task run();
        forever begin
            @(drv2mon_event_next);
            @(posedge v_register_if.clk);
            tr = new();
            this.tr.d = v_register_if.d;
            #1;
            this.tr.q = v_register_if.q;
            this.mon2scb_mbox.put(tr);
            tr.debug_print("MON");
        end
    endtask

endclass

class scoreboard;
    transaction tr;
    mailbox #(transaction) mon2scb_mbox;
    event scb2gen_event_next;

    int total_cnt = 0, pass_cnt = 0, fail_cnt = 0;

    function new(mailbox#(transaction) _mon2scb_mbox,
                 event _scb2gen_event_next);
        this.mon2scb_mbox = _mon2scb_mbox;
        this.scb2gen_event_next = _scb2gen_event_next;
    endfunction

    task run();
        forever begin
            this.mon2scb_mbox.get(tr);
            tr.debug_print("SCB");
            total_cnt = total_cnt + 1;
            if(tr.d == tr.q) begin
                $display("%t : PASS", $time);
                pass_cnt = pass_cnt + 1;
            end else begin
                $display("%t : FAIL d = %d q = %d", $time, tr.d, tr.q);
                fail_cnt = fail_cnt + 1;
            end
            ->scb2gen_event_next;
        end
    endtask

endclass

class environments;
    mailbox #(transaction) gen2drv_mbox;
    mailbox #(transaction) mon2scb_mbox;
    generator gen;
    driver drv;
    monitor mon;
    scoreboard scb;
    event scb2gen_event_next;
    event drv2mon_event_next;

    function new(virtual register_interface _v_register_if);
        this.gen2drv_mbox = new();
        this.mon2scb_mbox = new();
        this.gen = new(this.gen2drv_mbox, scb2gen_event_next);
        this.drv = new(_v_register_if, this.gen2drv_mbox, drv2mon_event_next);
        this.mon = new(_v_register_if, this.mon2scb_mbox, drv2mon_event_next);
        this.scb = new(this.mon2scb_mbox, scb2gen_event_next);
    endfunction

    task run();
        drv.reset_n();
        fork
            gen.run();
            drv.run();
            mon.run();
            scb.run();
        join_any
        $display("ENV fork join end");
        $display("[%t]TOTAL = %d", $time, scb.total_cnt);
        $display("[%t]PASS  = %d", $time, scb.pass_cnt);
        $display("[%t]FAIL  = %d", $time, scb.fail_cnt);
    endtask
endclass

module tb_register_8bit_sv ();
    register_interface register_if ();
    environments env;

    register_8bit_sv dut (
        .clk  (register_if.clk),
        .rst_n(register_if.rst_n),
        .d    (register_if.d),
        .q    (register_if.q)
    );

    always #5 register_if.clk = ~register_if.clk;

    initial begin
        register_if.clk   = 0;
        register_if.rst_n = 0;
        #1;
        register_if.rst_n = 1;
        env = new(register_if);
        env.run();

        $finish();
    end

endmodule
