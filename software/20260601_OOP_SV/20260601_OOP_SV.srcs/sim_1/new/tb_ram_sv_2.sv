`timescale 1ns / 1ps
`define MEMSIZE 4

interface ram_interface (
    input logic clk
);
    logic [`MEMSIZE-1:0] addr;
    logic en;
    logic [7:0] wdata;
    logic [7:0] rdata;
endinterface

class transaction;
    rand logic [`MEMSIZE-1:0] addr;
    rand logic en;
    rand logic [7:0] wdata;
    logic [7:0] rdata;
endclass

class generator;
    transaction tr;
    mailbox #(transaction) gen2drv_mbox;
    event drv2gen_evt;

    function new(mailbox#(transaction) _gen2drv_mbox, event _drv2gen_evt);
        this.gen2drv_mbox = _gen2drv_mbox;
        tr = new();
        drv2gen_evt = _drv2gen_evt;
    endfunction

    task run(int cnt);
        repeat (cnt) begin
            tr.randomize();
            this.gen2drv_mbox.put(tr);
            @(drv2gen_evt);
        end
    endtask
endclass

class driver;
    transaction tr;
    mailbox #(transaction) gen2drv_mbox;
    virtual ram_interface v_ram_if;
    event drv2gen_evt;

    function new(mailbox#(transaction) _gen2drv_mbox,
                 virtual ram_interface _v_ram_if, event _drv2gen_evt);
        this.gen2drv_mbox = _gen2drv_mbox;
        this.v_ram_if = _v_ram_if;
        this.drv2gen_evt = _drv2gen_evt;
    endfunction

    task run();
        forever begin
            this.gen2drv_mbox.get(tr);
            v_ram_if.addr = tr.addr;
            v_ram_if.en = tr.en;
            v_ram_if.wdata = tr.wdata;
            @(negedge v_ram_if.clk);
            ->drv2gen_evt;
        end
    endtask
endclass

class monitor;
    transaction tr;
    mailbox #(transaction) mon2scb_mbox;
    virtual ram_interface v_ram_if;

    function new(mailbox#(transaction) _mon2scb_mbox,
                 virtual ram_interface _v_ram_if);
        this.mon2scb_mbox = _mon2scb_mbox;
        this.v_ram_if = _v_ram_if;
        tr = new();
    endfunction

    task run();
        forever begin
            @(posedge v_ram_if.clk); #1;
            tr.addr =  v_ram_if.addr;
            tr.en  =    v_ram_if.en;
            tr.wdata = v_ram_if.wdata;
            tr.rdata = v_ram_if.rdata;
            mon2scb_mbox.put(tr);
        end
    endtask
endclass

class scoreboard;
    transaction tr;
    mailbox #(transaction) mon2scb_mbox;
    reg [7:0] mem [2**`MEMSIZE-1:0];

    int pass = 0;
    int fail = 0;

    function new(mailbox#(transaction) _mon2scb_mbox,
                 ref reg [7:0] _mem[2**`MEMSIZE-1:0]);
        this.mon2scb_mbox = _mon2scb_mbox;
        mem = _mem;
    endfunction

    task compare(transaction tr);
        if(tr.en) begin
            mem[tr.addr] = tr.wdata;
        end else begin
            if(tr.rdata === mem[tr.addr]) begin
                pass++;
                //$display("[%t][PASS] exp_mem[%d] = %d", $time, tr.addr, mem[tr.addr]);
                $display("[%t][PASS] exp_mem[%d] = %d, dut_mem[%d] = %d", $time, tr.addr, mem[tr.addr], tr.addr, tr.rdata);
            end else begin
                fail++;
                $display("[%t][FAIL] exp_mem[%d] = %d, dut_mem[%d] = %d", $time, tr.addr, mem[tr.addr], tr.addr, tr.rdata);
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
    generator gen;
    driver drv;
    scoreboard scb;
    monitor mon;
    mailbox #(transaction) gen2drv_mbox;
    mailbox #(transaction) mon2scb_mbox;
    event drv2gen_evt;

    reg [7:0] mem[2**`MEMSIZE-1:0];

    function new(virtual ram_interface _v_ram_if);
        gen2drv_mbox = new();
        mon2scb_mbox = new();
        gen = new(gen2drv_mbox, drv2gen_evt);
        drv = new(gen2drv_mbox, _v_ram_if, drv2gen_evt);
        scb = new(mon2scb_mbox, mem);
        mon = new(mon2scb_mbox, _v_ram_if);
    endfunction

    task run(int cnt);
        fork
            gen.run(cnt);
            drv.run();
            mon.run();
            scb.run();
        join_any
        $display("total cnt = %d", scb.pass + scb.fail);
        $display("pass cnt = %d", scb.pass);
        $display("fail cnt = %d", scb.fail);

        $finish();
    endtask

endclass

module tb_ram_sv_2 ();
    logic clk;

    environment env;
    ram_interface ram_if(clk);

    always #5 clk = ~clk;

    ram dut (
        .clk(ram_if.clk),
        .addr(ram_if.addr),
        .en(ram_if.en),
        .wdata(ram_if.wdata),
        .rdata(ram_if.rdata)
    );

    initial begin
        clk = 0;
        env = new(ram_if);
        env.run(1000);
    end

endmodule
