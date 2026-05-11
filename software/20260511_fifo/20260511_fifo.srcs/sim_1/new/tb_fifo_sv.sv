`timescale 1ns / 1ps

interface fifo_interface ();
    logic clk;
    logic rst_n;
    logic [7:0] push_data;
    logic push;
    logic pop;
    logic [7:0] pop_data;
    logic full;
    logic empty;
endinterface

class transaction;
    rand bit [7:0] push_data;
    rand bit push;
    rand bit pop;

    bit [7:0] pop_data;
    bit full;
    bit empty;

    task debug_print(string name);
        $display(
            "[%t] [%s] full = %d, empty =%d, push_data = %d, push = %d, pop = %d pop_data = %d",
            $time, name, full, empty, push_data, push, pop, pop_data);
    endtask
endclass

class generator;
    transaction tr;
    mailbox #(transaction) gen2drv_mbox;
    event event_scb2gen;

    function new(mailbox#(transaction) _gen2drv_mbox, event _event_scb2gen);
        this.gen2drv_mbox  = _gen2drv_mbox;
        this.event_scb2gen = _event_scb2gen;
    endfunction

    task run(int cnt);
        repeat (cnt) begin
            tr = new();
            tr.randomize();
            this.gen2drv_mbox.put(tr);
            tr.debug_print("GEN");
            @(event_scb2gen);
        end
    endtask
endclass

class driver;
    transaction tr;
    mailbox #(transaction) gen2drv_mbox;
    virtual fifo_interface v_fifo_if;

    function new(mailbox#(transaction) _gen2drv_mbox,
                 virtual fifo_interface _v_fifo_if);
        this.gen2drv_mbox = _gen2drv_mbox;
        this.v_fifo_if = _v_fifo_if;
    endfunction

    task preset();
        v_fifo_if.rst_n = 0;
        v_fifo_if.push_data = 0;
        v_fifo_if.push = 0;
        v_fifo_if.pop = 0;
        repeat (2) @(posedge v_fifo_if.clk);
        v_fifo_if.rst_n = 1;
    endtask

    task run();
        forever begin
            @(posedge v_fifo_if.clk);
            #1;
            this.gen2drv_mbox.get(tr);
            tr.debug_print("DRV");
            v_fifo_if.push_data = tr.push_data;
            v_fifo_if.push = tr.push;
            v_fifo_if.pop = tr.pop;
            // &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
            @(posedge v_fifo_if.clk);
            #1;
            v_fifo_if.push <= 0;
            v_fifo_if.pop  <= 0;
            // &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
        end
    endtask
endclass

class monitor;
    transaction tr;
    mailbox #(transaction) mon2scb_mbox;
    virtual fifo_interface v_fifo_if;

    function new(mailbox#(transaction) _mon2scb_mbox,
                 virtual fifo_interface _v_fifo_if);
        this.mon2scb_mbox = _mon2scb_mbox;
        this.v_fifo_if = _v_fifo_if;
    endfunction

    task run();
        forever begin
            @(negedge v_fifo_if.clk);
            tr = new();
            tr.push_data = v_fifo_if.push_data;
            tr.push = v_fifo_if.push;
            tr.pop = v_fifo_if.pop;
            tr.pop_data = v_fifo_if.pop_data;
            tr.full = v_fifo_if.full;
            tr.empty = v_fifo_if.empty;
            this.mon2scb_mbox.put(tr);
            tr.debug_print("MON");
        end
    endtask
endclass

class scoreboard;
    transaction tr;
    mailbox #(transaction) mon2scb_mbox;
    event event_scb2gen;

    int total_cnt = 0, pass_cnt = 0, fail_cnt = 0;
    logic [7:0] temp;

    logic [7:0] debug_fifo_queue[$:15];

    function new(mailbox#(transaction) _mon2scb_mbox, event _event_scb2gen);
        this.mon2scb_mbox  = _mon2scb_mbox;
        this.event_scb2gen = _event_scb2gen;
    endfunction

    task run();
        forever begin
            total_cnt++;
            this.mon2scb_mbox.get(tr);
            tr.debug_print("SCB");
            case ({
                tr.push, tr.pop
            })
                2'b01: begin
                    if (debug_fifo_queue.size() != 0) begin
                        temp = debug_fifo_queue.pop_back();
                        if (tr.pop_data == temp) begin
                            pass_cnt++;
                            $display(
                                "[%t][PASS] debug_fifo_queue = %d, pop_data = %d",
                                $time, temp, tr.pop_data);
                        end else begin
                            fail_cnt++;
                            $display(
                                "[%t][FIAL] debug_fifo_queue = %d, pop_data = %d",
                                $time, temp, tr.pop_data);
                        end
                    end
                end
                2'b10: begin
                    if (debug_fifo_queue.size() != 15) begin
                        debug_fifo_queue.push_front(tr.push_data);
                    end
                end
                2'b11: begin
                    if (debug_fifo_queue.size() == 15) begin
                        temp = debug_fifo_queue.pop_back();
                        if (tr.pop_data == temp) begin
                            pass_cnt++;
                            $display(
                                "[%t][PASS] debug_fifo_queue = %d, pop_data = %d",
                                $time, temp, tr.pop_data);
                        end else begin
                            fail_cnt++;
                            $display(
                                "[%t][FIAL] debug_fifo_queue = %d, pop_data = %d",
                                $time, temp, tr.pop_data);
                        end
                    end else if (debug_fifo_queue.size() == 0) begin
                        debug_fifo_queue.push_front(tr.push_data);
                    end else begin
                        temp = debug_fifo_queue.pop_back();
                        if (tr.pop_data == temp) begin
                            pass_cnt++;
                            $display(
                                "[%t][PASS] debug_fifo_queue = %d, pop_data = %d",
                                $time, temp, tr.pop_data);
                        end else begin
                            fail_cnt++;
                            $display(
                                "[%t][FIAL] debug_fifo_queue = %d, pop_data = %d",
                                $time, temp, tr.pop_data);
                        end
                        debug_fifo_queue.push_front(tr.push_data);
                    end
                end
                default: begin

                end
            endcase
            ->event_scb2gen;
        end
    endtask
endclass

class environment;
    mailbox #(transaction) gen2drv_mbox;
    mailbox #(transaction) mon2scb_mbox;
    generator gen;
    driver drv;
    scoreboard scb;
    monitor mon;
    event event_scb2gen;

    function new(virtual fifo_interface _v_fifo_if);
        gen2drv_mbox = new();
        mon2scb_mbox = new();
        gen = new(this.gen2drv_mbox, event_scb2gen);
        drv = new(this.gen2drv_mbox, _v_fifo_if);
        mon = new(this.mon2scb_mbox, _v_fifo_if);
        scb = new(this.mon2scb_mbox, event_scb2gen);
    endfunction

    task run();
        drv.preset();
        fork
            gen.run(100);
            drv.run();
            mon.run();
            scb.run();
        join_any

        $display("================end-fork join any================");
        $display("total_cnt = %d", scb.total_cnt);
        $display("pass_cnt = %d", scb.pass_cnt);
        $display("fail_cnt = %d", scb.fail_cnt);
        $display("================end-fork join any================");
        
        disable fork;
        $stop;
    endtask
endclass

module tb_fifo_sv ();
    fifo_interface fifo_if ();
    environment env;

    fifo dut (
        .clk(fifo_if.clk),
        .rst_n(fifo_if.rst_n),
        .push_data(fifo_if.push_data),
        .pop_data(fifo_if.pop_data),
        .push(fifo_if.push),
        .pop(fifo_if.pop),
        .full(fifo_if.full),
        .empty(fifo_if.empty)
    );

    always #5 fifo_if.clk = ~fifo_if.clk;

    initial begin
        fifo_if.clk = 0;
        env = new(fifo_if);
        env.run();
    end
endmodule
