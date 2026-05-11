`timescale 1ns / 1ps

class transaction;
    rand bit [7:0] addr;
    rand bit [7:0] wdata;
    bit      [7:0] rdata;
    rand bit       we;

    task debug_print(string name);
        $display("[%t][%s] addr = %d, wdata = %d, we = %d, rdata = %d", $time,
                 name, addr, wdata, we, rdata);
    endtask

    constraint addr_range {
        addr < 10;
    }
endclass

interface sram_interface ();
    logic       clk;
    logic [7:0] addr;
    logic [7:0] wdata;
    logic [7:0] rdata;
    logic       we;
endinterface

class generator;
    transaction tr;
    mailbox #(transaction) gen2drv_mbox;
    event event_scb2gen;

    function new(mailbox#(transaction) _gen2drv_mbox, event _event_scb2gen);
        this.gen2drv_mbox  = _gen2drv_mbox;
        this.event_scb2gen = _event_scb2gen;
    endfunction

    task run(int count);
        repeat (count) begin
            this.tr = new();
            
            // assertion
            assert (this.tr.randomize())
            else $error("[GEN] tr.randomize() error!");

            this.gen2drv_mbox.put(tr);
            this.tr.debug_print("GEN");
            @(event_scb2gen);
        end
    endtask
endclass


class driver;
    transaction tr;
    mailbox #(transaction) gen2drv_mbox;
    virtual sram_interface v_sram_if;

    function new(mailbox#(transaction) _gen2drv_mbox,
                 virtual sram_interface _v_sram_if);
        this.gen2drv_mbox = _gen2drv_mbox;
        this.v_sram_if = _v_sram_if;
    endfunction

    task preset();
        v_sram_if.addr = 0;
        v_sram_if.we = 0;
        v_sram_if.wdata = 0;
        @(posedge v_sram_if.clk);
    endtask

    task run();
        forever begin
            this.gen2drv_mbox.get(tr);
            this.tr.debug_print("DRV");
            @(posedge v_sram_if.clk);
            #1;
            this.v_sram_if.addr = tr.addr;
            this.v_sram_if.wdata = tr.wdata;
            this.v_sram_if.we = tr.we;
        end
    endtask
endclass


class scoreboard;
    transaction tr;
    mailbox #(transaction) mon2scb_mbox;
    event event_scb2gen;

    int total_cnt = 0, pass_cnt = 0, fail_cnt = 0;

    byte mem[256];

    function new(mailbox#(transaction) _mon2scb_mbox, event _event_scb2gen);
        this.mon2scb_mbox  = _mon2scb_mbox;
        this.event_scb2gen = _event_scb2gen;
    endfunction

    task run();
        forever begin
            this.mon2scb_mbox.get(tr);
            this.tr.debug_print("SCB");
            
            total_cnt ++;
            if(tr.we) begin
                mem[tr.addr] = tr.wdata;
            end else begin 
                if(tr.rdata == mem[tr.addr]) begin
                    pass_cnt ++;
                    $display("[%t] : PASS", $time);
                end else begin
                    fail_cnt ++;
                    $display("[%t] : FAIL addr = %d, rdata = %d, compare dta = %d",$time, tr.addr, tr.rdata, mem[tr.addr] );
                end
            end
            ->event_scb2gen;
        end
    endtask
endclass


class monitor;
    transaction tr;
    mailbox #(transaction) mon2scb_mbox;
    virtual sram_interface v_sram_if;

    function new(mailbox#(transaction) _mon2scb_mbox,
                 virtual sram_interface _v_sram_if);
        this.mon2scb_mbox = _mon2scb_mbox;
        this.v_sram_if = _v_sram_if;
    endfunction

    task run();
        forever begin
            @(posedge v_sram_if.clk);
            //#1;
            this.tr = new();
            this.tr.addr = v_sram_if.addr;
            this.tr.wdata = v_sram_if.wdata;
            this.tr.rdata = v_sram_if.rdata;
            this.tr.we = v_sram_if.we;
            this.mon2scb_mbox.put(tr);
            this.tr.debug_print("MON");
        end
    endtask
endclass

class environment;
    mailbox #(transaction) mon2scb_mbox;
    mailbox #(transaction) gen2drv_mbox;
    generator gen;
    driver drv;
    monitor mon;
    scoreboard scb;
    event event_scb2gen;

    function new(virtual sram_interface _v_sram_if);
        this.gen2drv_mbox = new();
        this.mon2scb_mbox = new();
        this.gen = new(this.gen2drv_mbox, event_scb2gen);
        this.drv = new(this.gen2drv_mbox, _v_sram_if);
        this.scb = new(this.mon2scb_mbox, event_scb2gen);
        this.mon = new(this.mon2scb_mbox, _v_sram_if);
    endfunction

    task run();
        drv.preset();
        fork
            gen.run(20);
            drv.run();
            mon.run();
            scb.run();
        join_any
        #10;
        $display("========================================================");
        $display("total = %d", scb.total_cnt);
        $display("pass = %d", scb.pass_cnt);
        $display("fail = %d", scb.fail_cnt);
        $display("========================================================");
        $stop;
    endtask

endclass

module tb_sram ();
    sram_interface sram_if ();
    environment env;

    sram dut (
        .clk  (sram_if.clk),
        .addr (sram_if.addr),
        .wdata(sram_if.wdata),
        .rdata(sram_if.rdata),
        .we   (sram_if.we)
    );

    always #5 sram_if.clk = ~sram_if.clk;

    initial begin
        sram_if.clk = 0;
        env = new(sram_if);
        env.run();
    end

endmodule
