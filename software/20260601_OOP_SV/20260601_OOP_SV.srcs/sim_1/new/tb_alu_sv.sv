`timescale 1ns / 1ps

interface alu_interface();
    logic opcode;
    logic [7:0] a;
    logic [7:0] b;
    logic [7:0] result;
endinterface

class tester;
    virtual alu_interface alu_if;

    function new(virtual alu_interface _alu_if);
        this.alu_if = _alu_if;
    endfunction

    task add_test(logic [7:0] add_a, logic [7:0] add_b);
        alu_if.opcode = 1'b0;
        alu_if.a = add_a;
        alu_if.b = add_b;
    endtask

    task sub_test(logic [7:0] add_a, logic [7:0] add_b);
        alu_if.opcode = 1'b1;
        alu_if.a = add_a;
        alu_if.b = add_b;
    endtask

endclass

module tb_alu_sv ();
    alu_interface alu_if ();
    tester BTS;
    tester BP;

    alu dut (
        .opcode(alu_if.opcode),
        .a     (alu_if.a),
        .b     (alu_if.b),
        .result(alu_if.result)
    );

    initial begin
        BTS = new(alu_if);
        BP = new(alu_if);

        BTS.add_test(10, 20);
        #10;
        BTS.sub_test(10, 20);
        #10;

        BP.add_test(10, 20);
        #10;
        BP.sub_test(10, 20);
        #10;

        $finish();
    end
endmodule
