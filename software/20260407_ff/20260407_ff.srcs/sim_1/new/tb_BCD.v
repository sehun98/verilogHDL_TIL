`timescale 1ns / 1ps

module tb_BCD;

    reg  [3:0] data_in;
    wire [6:0] seg;

    BCD u1_BCD (
        .data_in(data_in),
        .seg(seg)
    );

    integer i;
    initial begin
        for (i = 0; i < 10; i= i+1) begin
            data_in = i; #10;
        end        
    end
endmodule
