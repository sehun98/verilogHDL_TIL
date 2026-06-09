`timescale 1ns / 1ps

interface ram_interface (
    input logic clk  /*, input logic rst_n*/
);
    logic [7:0] addr;
    logic en;
    logic [7:0] wdata;
    logic [7:0] rdata;
endinterface

class transaction;
    rand logic [7:0] wdata;
    rand logic [7:0] addr;
    logic [7:0] rdata;
endclass

class tester;
    transaction tr;

    virtual ram_interface v_ram_if;

    function new(virtual ram_interface _v_ram_if);
        this.v_ram_if = _v_ram_if;
        tr = new();
    endfunction

    //task read(logic [7:0] addr);
    task read();
    @(negedge v_ram_if.clk);
        v_ram_if.en   = 1'b0;
        v_ram_if.addr = tr.addr;
        @(posedge v_ram_if.clk);
        #1;
        //$display("[%t] we:%0h, addr:%0h, rdata:%0h", $time, v_ram_if.en, v_ram_if.addr, v_ram_if.rdata);
        tr.rdata = v_ram_if.rdata;
    endtask

    //task write(logic [7:0] addr, logic [7:0] wdata);
    task write();
    @(negedge v_ram_if.clk);
        v_ram_if.en = 1'b1;
        v_ram_if.addr = tr.addr;
        v_ram_if.wdata = tr.wdata;
        @(posedge v_ram_if.clk);
        #1;
        //$display("[%t] we:%0h, addr:%0h, wdata:%0h", $time, v_ram_if.en, v_ram_if.addr, v_ram_if.wdata);
    endtask

    virtual function compare();
        if (tr.wdata !== tr.rdata) begin
            $display("[FAIL] wdata = %d, rdata = %d", tr.wdata, tr.rdata);
        end else begin
            $display("[PASS] wdata = %d, rdata = %d", tr.wdata, tr.rdata);
        end
    endfunction

    virtual task test_run(int loop);
        repeat (loop) begin
            tr.randomize();
            write();
            read();
            compare();
        end
    endtask
endclass

class tester_child extends tester;
    int pass, fail;
    
    function new(virtual ram_interface _v_ram_if);
        super.new(_v_ram_if);
        pass = 0;
        fail = 0;
    endfunction

    virtual function compare();
        if (tr.wdata != tr.rdata) begin
            $display("[FAIL] wdata = %d, rdata = %d", tr.wdata, tr.rdata);
            fail++;
        end else begin
            $display("[PASS] wdata = %d, rdata = %d", tr.wdata, tr.rdata);
            pass++;
        end
    endfunction

    function report();
        $display("total test count : %d", pass + fail);
        $display("fail count : %d", fail);
        $display("pass count : %d", pass);
    endfunction

    virtual task test_run(int loop);
        repeat (loop) begin
            tr.randomize();
            write();
            read();
            compare();
        end
        report();
    endtask
endclass

module tb_ram_sv ();
    logic clk;

    ram_interface ram_if (clk);
    tester_child ts;

    ram dut (
        .clk(clk),
        .addr(ram_if.addr),
        .en(ram_if.en),
        .wdata(ram_if.wdata),
        .rdata(ram_if.rdata)
    );

    always #5 clk = ~clk;

    initial begin

        clk = 0;
        repeat(5) @(posedge clk);
        ts  = new(ram_if);

        /*
        ts.write(8'h0a, 8'h01);
        ts.write(8'h0b, 8'h02);
        ts.write(8'h0c, 8'h03);        
        ts.write(8'h0d, 8'h04);
        ts.read(8'h0a);
        ts.read(8'h0b);
        ts.read(8'h0c);
        ts.read(8'h0d);
        */
        ts.test_run(10);

        $finish();
    end

endmodule
