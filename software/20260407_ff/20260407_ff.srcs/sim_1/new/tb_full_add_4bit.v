`timescale 1ns / 1ps

module tb_full_add_4bit;
    reg [3:0] a; // 0~15
    reg [3:0] b;
    reg c_in;
    wire [3:0] s;
    wire c_out;

initial begin
    a = 0; b = 0; c_in = 0;
end

integer i,j;

initial begin
    for(i=0;i<16;i=i+1) begin
        for(j=0;j<16;j=j+1) begin
            a=i; b=j; #10;
        end
    end
end

full_add_4bit tb_full_add_4bit(
    .a(a),
    .b(b),
    .c_in(c_in),
    .s(s),
    .c_out(c_out)
    );
endmodule
