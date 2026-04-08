`timescale 1ns / 1ps

module top_adder(
    input  wire [3:0] a,
    input  wire [3:0] b,
    input  wire       c_in, // cin
    output wire [0:7] seg, // fnd_data
    output wire       c_out, // led
    output wire [3:0] digit //fnd_com
);

    wire [3:0] w_s;
    wire [0:7] seg_raw;

    assign digit = 4'b1110;
    assign seg   = ~seg_raw;

    full_add_4bit u_full_add_4bit (
        .a    (a),
        .b    (b),
        .c_in (c_in),
        .s    (w_s),
        .c_out(c_out)
    );

    BCD u_BCD (
        .data_in(w_s),
        .seg    (seg_raw)
    );


endmodule