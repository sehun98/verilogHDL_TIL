`timescale 1ns / 1ps

module full_add (
    input  wire a,
    input  wire b,
    input  wire c_in,
    output wire sum,
    output wire c_out
);
    wire w1;
    wire w2;
    wire w3;

    assign c_out = w3 | w2;

    half_add u1_half_add (
        .a(a),
        .b(b),
        .c_out(w2),
        .sum(w1)
    );

    half_add u2_half_add (
        .a(w1),
        .b(c_in),
        .c_out(w3),
        .sum(sum)
    );

endmodule
