`timescale 1ns / 1ps

module full_add_8bit (
    input wire [7:0] a,
    input wire [7:0] b,
    output wire [7:0] sum,
    output wire c_out
);

    wire c_0;

    full_add_4bit u1_full_add_4bit (
        .a(a[3:0]),
        .b(b[3:0]),
        .c_in(1'b0),
        .s(sum[3:0]),
        .c_out(c_0)
    );

    full_add_4bit u2_full_add_4bit (
        .a(a[7:4]),
        .b(b[7:4]),
        .c_in(c_0),
        .s(sum[7:4]),
        .c_out(c_out)
    );


endmodule
