`timescale 1ns / 1ps

module gray2binary #(
    parameter WIDTH = 8
)(
    input  wire [WIDTH-1:0] gray,
    output wire [WIDTH-1:0] bin
);

    /* 
     * gray bin
     * 0000 0000
     * 0001 0001
     * 0011 0010
     * 0010 0011
     * 0110 0100
     * 0111 0101
     * 0101 0110
     * 0100 0111
     * 1100 1000
     * 1101 1001
     * 1111 1010
     */
    genvar i;

    // MSB는 그대로
    assign bin[WIDTH-1] = gray[WIDTH-1];

    // 나머지는 누적 XOR
    generate
        for (i = WIDTH-2; i >= 0; i = i - 1) begin : GEN_BIN
            assign bin[i] = bin[i+1] ^ gray[i];
        end
    endgenerate

endmodule