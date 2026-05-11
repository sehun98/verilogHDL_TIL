`timescale 1ns / 1ps

interface FND_Controller_interface ();
    logic clk;
    logic rst_n;
    logic [13:0] data;
    logic [3:0] digit;
    logic [7:0] seg;
endinterface

class transaction;
    bit rst_n;
    rand bit [13:0] data;
    bit [3:0] digit;
    bit [7:0] seg;

    constraint data_rate {
        data < 10000;
    }

/*
    constraint in_rage {
        data 
    }
    */

    /*    
    constraint in_range {
        a>128;
        b>250;
    }

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
    constraint c5 {
        solve mode before b;
    }

    constraint c6 {
        unique {arr};
    }
    */

    task debug_print(string name);
        begin
            $display("[%s][%t] data = %b, digit = %b, seg = %b", name, $time,
                     data, digit, seg);
        end
    endtask
endclass

class generator;
    transaction tr;
    mailbox #(transaction) gen2drv_mbox;
    event event_scb2gen;

    function new(mailbox#(transaction) _gen2drv_mbox, event _event_scb2gen);
        this.gen2drv_mbox = _gen2drv_mbox;
        event_scb2gen = _event_scb2gen;
    endfunction

    task run();
        repeat (10) begin
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
    virtual FND_Controller_interface v_FND_Controller_if;
    event event_drv2mon;

    function new(virtual FND_Controller_interface _v_FND_Controller_if,
                 mailbox#(transaction) _gen2drv_mbox,
                 event _event_drv2mon);
        this.v_FND_Controller_if = _v_FND_Controller_if;
        this.gen2drv_mbox = _gen2drv_mbox;
        this.event_drv2mon = _event_drv2mon;
    endfunction

    task run();
        forever begin
            this.gen2drv_mbox.get(tr);
            v_FND_Controller_if.data  = tr.data;
            #4000_000;
            tr.debug_print("DRV");
            -> event_drv2mon;
        end
    endtask
endclass

class monitor;
    transaction tr;
    mailbox #(transaction) mon2scb_mbox;
    virtual FND_Controller_interface v_FND_Controller_if;
    event event_drv2mon;

    function new(virtual FND_Controller_interface _v_FND_Controller_if,
                 mailbox#(transaction) _mon2scb_mbox,
                 event _event_drv2mon);
        this.v_FND_Controller_if = _v_FND_Controller_if;
        this.mon2scb_mbox = _mon2scb_mbox;
        this.event_drv2mon = _event_drv2mon;
    endfunction

    task run();
        forever begin
            @(event_drv2mon);
            this.tr = new();
            this.tr.data = this.v_FND_Controller_if.data;
            this.tr.digit = this.v_FND_Controller_if.digit;
            this.tr.seg = this.v_FND_Controller_if.seg;
            this.mon2scb_mbox.put(tr);
            tr.debug_print("MON");
        end
    endtask
endclass

class scoreboard;
    transaction tr;
    mailbox #(transaction) mon2scb_mbox;
    event event_scb2gen;

    function new(mailbox#(transaction) _mon2scb_mbox, event _event_scb2gen);
        this.mon2scb_mbox = _mon2scb_mbox;
        this.event_scb2gen = _event_scb2gen;
    endfunction

    function automatic logic [7:0] seg_ref(input logic [3:0] num);
        case (num)
            4'd0: seg_ref = 8'hC0;
            4'd1: seg_ref = 8'hF9;
            4'd2: seg_ref = 8'hA4;
            4'd3: seg_ref = 8'hB0;
            4'd4: seg_ref = 8'h99;
            4'd5: seg_ref = 8'h92;
            4'd6: seg_ref = 8'h82;
            4'd7: seg_ref = 8'hF8;
            4'd8: seg_ref = 8'h80;
            4'd9: seg_ref = 8'h90;
            default: seg_ref = 8'hFF;
        endcase
    endfunction

    function automatic logic [3:0] digit_ref(input logic [13:0] data,
                                             input logic [3:0] fnd_sel);
        logic [3:0] data_1;
        logic [3:0] data_10;
        logic [3:0] data_100;
        logic [3:0] data_1000;

        begin
            data_1    = data % 10;
            data_10   = (data / 10) % 10;
            data_100  = (data / 100) % 10;
            data_1000 = (data / 1000) % 10;

            case (fnd_sel)
                4'b1110: digit_ref = data_1;
                4'b1101: digit_ref = data_10;
                4'b1011: digit_ref = data_100;
                4'b0111: digit_ref = data_1000;
                default: digit_ref = 4'hF;
            endcase
        end
    endfunction

    int pass_cnt, fail_cnt, total_cnt;

    task compare(input logic [13:0] data, input logic [3:0] fnd_sel,
                 input logic [7:0] actual_seg);
        logic [3:0] expected_digit;
        logic [7:0] expected_seg;

        expected_digit = digit_ref(data, fnd_sel);
        expected_seg = seg_ref(expected_digit);

        total_cnt = total_cnt + 1;
        if (actual_seg !== expected_seg) begin
            $error(
                "[FND FAIL] data=%0d fnd_sel=%b digit=%0d expected_seg=%h actual_seg=%h",
                data, fnd_sel, expected_digit, expected_seg, actual_seg);
            fail_cnt = fail_cnt + 1;
        end else begin
            $display("[FND PASS] data=%0d fnd_sel=%b digit=%0d seg=%h", data,
                     fnd_sel, expected_digit, actual_seg);
            pass_cnt = pass_cnt + 1;
        end
    endtask

    task run();
        forever begin
            this.mon2scb_mbox.get(tr);
            this.tr.debug_print("SCB");
            compare(tr.data, tr.digit, tr.seg);
            -> event_scb2gen;
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
    event event_scb2gen;
    event event_drv2mon;

    function new(virtual FND_Controller_interface _v_FND_Controller_if);
        gen2drv_mbox = new();
        mon2scb_mbox = new();
        gen = new(this.gen2drv_mbox, this.event_scb2gen);
        drv = new(_v_FND_Controller_if, this.gen2drv_mbox, this.event_drv2mon);
        mon = new(_v_FND_Controller_if, this.mon2scb_mbox, this.event_drv2mon);
        scb = new(this.mon2scb_mbox, this.event_scb2gen);
    endfunction

    task run();
        //drv.reset_n();
        fork
            gen.run();
            drv.run();
            mon.run();
            scb.run();
        join_any
    endtask
endclass

module tb_FND_Controller_sv ();
    FND_Controller_interface FND_Controller_if ();
    environment env;

    FND_Controller u1_FND_Controller (
        .clk  (FND_Controller_if.clk),
        .rst_n(FND_Controller_if.rst_n),
        .data (FND_Controller_if.data),
        .digit(FND_Controller_if.digit),
        .seg  (FND_Controller_if.seg)
    );

    always #5 FND_Controller_if.clk = ~FND_Controller_if.clk;

    initial begin
        FND_Controller_if.clk = 1'b0;
        FND_Controller_if.rst_n = 1'b0;
        repeat (2) @(posedge FND_Controller_if.clk);
        FND_Controller_if.rst_n = 1'b1;
        env = new(FND_Controller_if);
        env.run();
    end
endmodule
