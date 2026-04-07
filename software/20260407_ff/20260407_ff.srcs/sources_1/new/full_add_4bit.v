`timescale 1ns / 1ps

module full_add_4bit(
    input wire [3:0] a,
    input wire [3:0] b,
    input wire c_in,
    output wire [3:0] s,
    output wire c_out
    );

wire [2:0] c;

full_add u1_full_add (
    .a(a[0]),
    .b(b[0]),
    .c_in(c_in),

    .sum(s[0]),
    .c_out(c[0])
);

full_add u2_full_add (
    .a(a[1]),
    .b(b[1]),
    .c_in(c[0]),

    .sum(s[1]),
    .c_out(c[1])
);

full_add u3_full_add (
    .a(a[2]),
    .b(b[2]),
    .c_in(c[1]),

    .sum(s[2]),
    .c_out(c[2])
);

full_add u4_full_add (
    .a(a[3]),
    .b(b[3]),
    .c_in(c[2]),

    .sum(s[3]),
    .c_out(c_out)
);

endmodule
