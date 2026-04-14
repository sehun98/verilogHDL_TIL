`timescale 1ns / 1ps

module tb_gray2binary;
    reg  [3:0] gray;
    wire [3:0] bin;

    gray2binary #(
        .WIDTH(4)
    ) u1_gray2binary (
        .gray(gray),
        .bin (bin)
    );

    reg [3:0] bin0 = 4'd0;
    reg [3:0] bin1 = 4'd1;
    reg [3:0] bin2 = 4'd2;
    reg [3:0] bin3 = 4'd3;
    reg [3:0] bin4 = 4'd4;
    reg [3:0] bin5 = 4'd5;
    reg [3:0] bin6 = 4'd6;
    reg [3:0] bin7 = 4'd7;
    reg [3:0] bin8 = 4'd8;
    reg [3:0] bin9 = 4'd9;

    initial begin

        gray = 4'b0000;
        #100;
        if (bin == bin0) $strobe("SUCCESS : GRAY TO BIN 0");
        else             $strobe("FAIL : GRAY TO BIN 0");

        gray = 4'b0001;
        #100;
        if (bin == bin1) $strobe("SUCCESS : GRAY TO BIN 1");
        else             $strobe("FAIL : GRAY TO BIN 1");

        gray = 4'b0011;
        #100;
        if (bin == bin2) $strobe("SUCCESS : GRAY TO BIN 2");
        else             $strobe("FAIL : GRAY TO BIN 2");

        gray = 4'b0010;
        #100;
        if (bin == bin3) $strobe("SUCCESS : GRAY TO BIN 3");
        else             $strobe("FAIL : GRAY TO BIN 3");

        gray = 4'b0110;
        #100;
        if (bin == bin4) $strobe("SUCCESS : GRAY TO BIN 4");
        else             $strobe("FAIL : GRAY TO BIN 4");

        gray = 4'b0111;
        #100;
        if (bin == bin5) $strobe("SUCCESS : GRAY TO BIN 5");
        else             $strobe("FAIL : GRAY TO BIN 5");

        gray = 4'b0101;
        #100;
        if (bin == bin6) $strobe("SUCCESS : GRAY TO BIN 6");
        else             $strobe("FAIL : GRAY TO BIN 6");

        gray = 4'b0100;
        #100;
        if (bin == bin7) $strobe("SUCCESS : GRAY TO BIN 7");
        else             $strobe("FAIL : GRAY TO BIN 7");

        gray = 4'b1100;
        #100;
        if (bin == bin8) $strobe("SUCCESS : GRAY TO BIN 8");
        else             $strobe("FAIL : GRAY TO BIN 8");
        
        gray = 4'b1101;
        #100;
        if (bin == bin9) $strobe("SUCCESS : GRAY TO BIN 9");
        else             $strobe("FAIL : GRAY TO BIN 9");

        $finish;
    end

endmodule
