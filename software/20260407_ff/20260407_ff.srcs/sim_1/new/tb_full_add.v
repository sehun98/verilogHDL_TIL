`timescale 1ns / 1ps

module tb_full_add;
    reg  a;
    reg  b;
    reg  c_in;
    wire c_out;
    wire sum;

    initial begin
        {a, b, c_in} = 3'b000;
        #10;
        {a, b, c_in} = 3'b001;
        #10;
        {a, b, c_in} = 3'b010;
        #10;
        {a, b, c_in} = 3'b011;
        #10;        
        {a, b, c_in} = 3'b100;
        #10;
        {a, b, c_in} = 3'b101;
        #10;
        {a, b, c_in} = 3'b110;
        #10;
        {a, b, c_in} = 3'b111;
        #10;
    end


    full_add u1_full_add (
        .a(a),
        .b(b),
        .c_in(c_in),
        .sum(sum),
        .c_out(c_out)
    );

endmodule
