`timescale 1ns / 1ps

interface datapath_interface ();
    logic clk;
    logic rst_n;
    logic run;
    logic clear;
    logic mode;
    logic ick_count;
endinterface

class transaction;
    bit clk;
    bit rst_n;

    rand bit run;
    rand bit clear;
    rand bit mode;

    bit tick_count;

    task debug_print(string name);
        $display("[%t][%s] run = %d, clear = %d, mode = %d, tick_count =%d",
                 $time, name, run, clear, mode, tick_count);
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
    virtual control_unit_interface control_unit_if;
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
            v_control_unit_if.btn_run   = tr.btn_run;
            v_control_unit_if.btn_clear = tr.btn_clear;
            v_control_unit_if.btn_mode  = tr.btn_mode;
            tr.debug_print("DRV");
            ->event_drv2gen;
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
            mon2scb_mbox.get(tr);
            // tr.btn_run;
            // tr.btn_clear;
            // tr.btn_mode;
            // tr.run;
            // tr.clear;
            // tr.mode;
            tr.debug_print("SCB");
        end
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
            tr.btn_run   = v_control_unit_if.btn_run;
            tr.btn_clear = v_control_unit_if.btn_clear;
            tr.btn_mode  = v_control_unit_if.btn_mode;
            tr.run       = v_control_unit_if.run;
            tr.clear     = v_control_unit_if.clear;
            tr.mode      = v_control_unit_if.mode;
            mon2scb_mbox.put(tr);
            tr.debug_print("MON");
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

    function new(virtual control_unit_interface v_control_unit_if);
        gen2drv_mbox = new();
        mon2scb_mbox = new();
        gen = new(gen2drv_mbox, event_drv2gen);
        drv = new(gen2drv_mbox, v_control_unit_if, event_drv2gen);
        mon = new(mon2scb_mbox, v_control_unit_if);
        scb = new(mon2scb_mbox);
    endfunction

    task run();
        //drv.reset();
        fork
            gen.run(10);
            drv.run();
            mon.run();
            scb.run();
        join_any
    endtask
endclass

module tb_datapath_sv ();
    data_path_interface data_path_if ();
    environment env;

    data_path dut (
        .clk       (data_path_if.clk),
        .rst_n     (data_path_if.rst_n),
        .run       (data_path_if.run),
        .clear     (data_path_if.clear),
        .mode      (data_path_if.mode),
        .tick_count(data_path_if.tick_count)
    );

    always #5 data_path_if.clk = ~data_path_if.clk;

    initial begin
        data_path_if.clk = 0;
        env = new(data_path_if);
        env.run();
    end
endmodule
