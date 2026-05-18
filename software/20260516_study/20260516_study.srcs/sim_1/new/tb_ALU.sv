`timescale 1ns / 1ps

interface ALU_interface ();
    logic [7:0] a;
    logic [7:0] b;
    logic [2:0] op_code;
    logic zero_flag;
    logic [7:0] out;
endinterface

class transaction;
    rand logic [7:0] a;
    rand logic [7:0] b;
    rand logic [2:0] op_code;  // 111
    logic zero_flag;
    logic [7:0] out;

    task debug_print(string name);
        case (op_code)
            3'd0:
            $display(
                "[%t][ADD] a = %d, b = %d, out = %d, zero_flag = %d",
                $time,
                a,
                b,
                out,
                zero_flag
            );
            3'd1:
            $display(
                "[%t][SUB] a = %d, b = %d, out = %d, zero_flag = %d",
                $time,
                a,
                b,
                out,
                zero_flag
            );
            3'd2:
            $display(
                "[%t][OR] a = %d, b = %d, out = %d, zero_flag = %d",
                $time,
                a,
                b,
                out,
                zero_flag
            );
            3'd3:
            $display(
                "[%t][AND] a = %d, b = %d, out = %d, zero_flag = %d",
                $time,
                a,
                b,
                out,
                zero_flag
            );
            3'd4:
            $display(
                "[%t][XOR] a = %d, b = %d, out = %d, zero_flag = %d",
                $time,
                a,
                b,
                out,
                zero_flag
            );
            3'd5:
            $display(
                "[%t][NOT] a = %d, b = %d, out = %d, zero_flag = %d",
                $time,
                a,
                b,
                out,
                zero_flag
            );
            3'd6:
            $display(
                "[%t][BUFF] a = %d, b = %d, out = %d, zero_flag = %d",
                $time,
                a,
                b,
                out,
                zero_flag
            );
            default:
            $display(
                "[%t][BUFF] a = %d, b = %d, out = %d, zero_flag = %d",
                $time,
                a,
                b,
                out,
                zero_flag
            );
        endcase
    endtask
endclass

class generator;
    transaction tr;
    mailbox #(transaction) gen2drv;
    event event_drv2gen;

    function new(mailbox#(transaction) _gen2drv, event _event_drv2gen);
        gen2drv = _gen2drv;
        event_drv2gen = _event_drv2gen;
    endfunction

    task run(int cnt);
        repeat (cnt) begin
            tr = new();
            tr.randomize();
            gen2drv.put(tr);
            tr.debug_print("GEN");
            @(event_drv2gen);
        end
    endtask
endclass

class driver;
    transaction tr;
    mailbox #(transaction) gen2drv;
    virtual ALU_interface v_ALU_if;
    event event_drv2gen;

    function new(mailbox#(transaction) _gen2drv,
                 virtual ALU_interface _v_ALU_if, event _event_drv2gen);
        gen2drv = _gen2drv;
        v_ALU_if = _v_ALU_if;
        event_drv2gen = _event_drv2gen;
    endfunction

    task preset();
        v_ALU_if.a = 8'd0;
        v_ALU_if.b = 8'd0;
        v_ALU_if.op_code = 8'd0;
    endtask

    task run();
        forever begin
            gen2drv.get(tr);
            v_ALU_if.a = tr.a;
            v_ALU_if.b = tr.b;
            v_ALU_if.op_code = tr.op_code;
            #10;
            ->event_drv2gen;
            tr.debug_print("DRV");
        end
    endtask
endclass

class monitor;
    transaction tr;
    mailbox #(transaction) mon2scb;
    virtual ALU_interface v_ALU_if;

    function new(mailbox#(transaction) _mon2scb,
                 virtual ALU_interface _v_ALU_if);
        mon2scb  = _mon2scb;
        v_ALU_if = _v_ALU_if;
    endfunction

    task run();
        forever begin
            #5;
            tr = new();
            tr.a = v_ALU_if.a;
            tr.b = v_ALU_if.b;
            tr.op_code = v_ALU_if.op_code;
            tr.zero_flag = v_ALU_if.zero_flag;
            tr.out = v_ALU_if.out;
            mon2scb.put(tr);
            tr.debug_print("MON");
        end
    endtask
endclass

class scoreboard;
    transaction tr;
    mailbox #(transaction) mon2scb;

    function new(mailbox#(transaction) _mon2scb);
        mon2scb = _mon2scb;
    endfunction

    logic [7:0] exp_out;
    logic exp_zero_flag;

    int total_cnt_out = 0, pass_cnt_out = 0, fail_cnt_out = 0;
    int total_cnt_zero_flag = 0, pass_cnt_zero_flag = 0, fail_cnt_zero_flag = 0;

    task compare(transaction tr);
        total_cnt_out++;
        total_cnt_zero_flag++;

        case (tr.op_code)
            3'd0: exp_out = tr.a + tr.b;
            3'd1: exp_out = tr.a - tr.b;
            3'd2: exp_out = tr.a | tr.b;
            3'd3: exp_out = tr.a & tr.b;
            3'd4: exp_out = tr.a ^ tr.b;
            3'd5: exp_out = ~tr.a;
            3'd6: exp_out = tr.a;
            default: exp_out = tr.a;
        endcase

        if (exp_out == 8'd0) begin
            exp_zero_flag = 1'b1;
        end else begin
            exp_zero_flag = 1'b0;
        end

        if (exp_zero_flag == tr.zero_flag) begin
            pass_cnt_zero_flag++;
        end else begin
            fail_cnt_zero_flag++;
        end

        if (exp_out == tr.out) begin
            pass_cnt_out++;
        end else begin
            tr.debug_print("COMP");
            fail_cnt_out++;
        end
    endtask

    task run();
        forever begin
            mon2scb.get(tr);
            compare(tr);
            tr.debug_print("MON");
        end
    endtask
endclass

class environments;
    mailbox #(transaction) gen2drv;
    mailbox #(transaction) mon2scb;
    generator gen;
    driver drv;
    monitor mon;
    scoreboard scb;
    event event_drv2gen;

    function new(virtual ALU_interface _v_ALU_if);
        gen2drv = new();
        mon2scb = new();
        gen = new(gen2drv, event_drv2gen);
        drv = new(gen2drv, _v_ALU_if, event_drv2gen);
        mon = new(mon2scb, _v_ALU_if);
        scb = new(mon2scb);
    endfunction

    task run();
        drv.preset();
        fork
            gen.run(1000);
            drv.run();
            mon.run();
            scb.run();
        join_any

        $display("out total_cnt[%d], out pass_cnt[%d], out fail_cnt[%d]",scb.total_cnt_out, scb.pass_cnt_out, scb.fail_cnt_out);
        $display("zero total_cnt[%d], zero pass_cnt[%d], zero fail_cnt[%d]",scb.total_cnt_zero_flag, scb.pass_cnt_zero_flag, scb.fail_cnt_zero_flag);

        #100;
        $finish;
    endtask
endclass

module tb_ALU ();
    ALU_interface ALU_if ();
    environments env;

    ALU dut (
        .a        (ALU_if.a),
        .b        (ALU_if.b),
        .op_code  (ALU_if.op_code),
        .zero_flag(ALU_if.zero_flag),
        .out      (ALU_if.out)
    );

    initial begin
        env = new(ALU_if);
        env.run();
    end
endmodule
