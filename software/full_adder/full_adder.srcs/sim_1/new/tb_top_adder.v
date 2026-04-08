`timescale 1ns / 1ps

module tb_top_adder;
    reg  [3:0] a;
    reg  [3:0] b;
    reg        c_in;

    wire [0:7] seg; 
    wire       c_out;
    wire [3:0] digit;

    initial begin
        a = 4'b0000;
        b = 4'b0000;
        c_in = 1'b0;
    end

    integer i;

    initial begin
        a = 4'b0000;
        b = 4'b0000;
        for (i = 0; i < 16; i = i + 1) begin
            b = i[3:0];
            #10;
        end
    end

    top_adder u_top_adder (
        .a(a),
        .b(b),
        .c_in(c_in),

        .seg  (seg),
        .c_out(c_out),
        .digit(digit)
    );

endmodule
