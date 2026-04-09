`timescale 1ns / 1ps

module tb_BCD;

    reg  [3:0] data_in;
    wire [7:0] seg;

    BCD u1_BCD (
        .data_in(data_in),
        .seg(seg)
    );

    integer i;

    // -------------------------------
    // Case 1 : full case
    // data_in : 0~15
    // -------------------------------
    initial begin
        for (i = 0; i < 16; i = i + 1) begin
            data_in = i;
            #10;
        end
    end

    // -------------------------------
    // Case 2 : boundary case
    // data_in : 16
    // -------------------------------
    initial begin
        data_in = 16;
        #10;
    end


    initial begin
        #3_000_000;
        $finish;
    end
endmodule
