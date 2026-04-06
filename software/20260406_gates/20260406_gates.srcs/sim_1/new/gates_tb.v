//////////////////////////////////////////////////////////////////////////////////
//  To test simulation environment module
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

module gates_tb;
    reg a, b;
    wire [6:0] y;

    initial begin
        {a, b} = 2'b00;
        #10{a, b} = 2'b01;
        #10{a, b} = 2'b10;
        #10{a, b} = 2'b11;
        #10 $finish();
    end

    gates u1_gates (
        .a(a),
        .b(b),
        .y(y)
    );
endmodule


