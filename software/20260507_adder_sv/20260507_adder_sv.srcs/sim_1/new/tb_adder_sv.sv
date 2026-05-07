`timescale 1ns / 1ps

interface adder_interface(); // (2)
    logic [7:0] a;
    logic [7:0] b;
    logic       mode;
    logic [7:0] sum;
    logic       carry;
endinterface

// random 대상 : a, b, mode
// transaction
class transaction; // (10)
    rand bit [7:0] a;
    rand bit [7:0] b;
    rand bit       mode;
    bit      [7:0] sum;
    bit            carry;
endclass

class generator; // (4)
    virtual adder_interface adder_vif; // (6)
    transaction tr; // (11)

    function new (virtual adder_interface adder_vinterf); // (7)
        adder_vif = adder_vinterf; // (8)
        tr = new; // (12)
    endfunction

    task run(int cnt); // (13)
        repeat(cnt) begin
            tr.randomize(); // rand 가 붙은 것에 자동 랜덤 생성
            adder_vif.a = tr.a;
            adder_vif.b = tr.b;
            adder_vif.mode = tr.mode;
            #10;
        end
    endtask
endclass

// randomize -> stimulus drive -> monitoring -> exptect pass & fail score board
// tb, sw 객체와 interface를 3개를 생성     
module tb_adder_sv();
    adder_interface adder_if(); // (3)
    generator gen; // (5)

    adder_sv u1_adder_sv ( // (1)
        .a    (adder_if.a),
        .b    (adder_if.b),
        .mode (adder_if.mode),
        .sum  (adder_if.sum),
        .carry(adder_if.carry)
    );

    initial begin // (9)
        gen = new(adder_if);
        gen.run(10);
        $stop();
    end
endmodule


// 1. testbench
// 2. interface
// 3. sw 객체

