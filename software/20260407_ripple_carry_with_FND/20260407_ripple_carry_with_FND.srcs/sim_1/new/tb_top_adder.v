`timescale 1ns / 1ps

module tb_top_adder;
    reg [3:0] a;
    reg [3:0] b;
    reg       c_in; // cin
    
    wire [0:7] seg; // fnd_data
    wire       c_out; // led
    wire [3:0] digit; //fnd_com

initial begin
    a = 4'b0000; b = 4'b0000; c_in = 1'b0;
end

integer i,j;

// 0
// 1
// 2
// 3
// 4
// 5
// 6
// 
initial begin
    a = 4'b0000; b = 4'd1; #10;
    a = 4'b0000; b = 4'd2; #10;
    a = 4'b0000; b = 4'd3; #10;
    a = 4'b0000; b = 4'd4; #10;
    a = 4'b0000; b = 4'd5; #10;
    a = 4'b0000; b = 4'd6; #10;
    a = 4'b0000; b = 4'd7; #10;
    a = 4'b0000; b = 4'd8; #10;
    a = 4'b0000; b = 4'd9; #10;
    a = 4'b0000; b = 4'd10; #10;
    a = 4'b0000; b = 4'd11; #10;
    a = 4'b0000; b = 4'd12; #10;
    a = 4'b0000; b = 4'd13; #10;
    a = 4'b0000; b = 4'd14; #10;
    a = 4'b0000; b = 4'd15; #10;
end

top_adder u_top_adder (
    .a(a),
    .b(b),
    .c_in(c_in),

    .seg(seg),
    .c_out(c_out),
    .digit(digit)
);

endmodule
