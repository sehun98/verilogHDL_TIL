`timescale 1ns / 1ps

module tb_half_add;
    reg  a;
    reg  b;
    wire c_out;
    wire sum;

    initial begin
        {a, b} = 2'b00;
        #10;
        {a, b} = 2'b01;
        #10;
        {a, b} = 2'b10;
        #10;
        {a, b} = 2'b11;
        #10;
    end

    half_add u1_half_add (
        .a(a),
        .b(b),
        .c_out(c_out),
        .sum(sum)
    );
endmodule
