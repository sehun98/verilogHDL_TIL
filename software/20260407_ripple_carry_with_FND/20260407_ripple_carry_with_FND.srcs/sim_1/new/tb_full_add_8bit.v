`timescale 1ns / 1ps

module tb_full_add_8bit;
    reg [7:0] a;
    reg [7:0] b;
    wire [7:0] s;
    wire c_out;

initial begin
    a = 8'b0000_0000; b = 8'b0000_0000;
end

integer i,j;

initial begin
    for(i=0;i<256;i=i+1) begin
        for(j=0;j<256;j=j+1) begin
            a=i; b=j; #10;
        end
    end
end

// initial begin
//     for(i=0;i<16;i=i+1) begin
//         for(j=0;j<16;j=j+1) begin
//             a=i; b=j; #10;
//         end
//     end
// end

full_add_8bit tb_full_add_8bit(
    .a(a),
    .b(b),
    .sum(s),
    .c_out(c_out)
    );

endmodule