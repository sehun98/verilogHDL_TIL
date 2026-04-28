`timescale 1ns / 1ps

module tb_register_8bit;

    reg clk;
    reg rst_n;
    reg [7:0] d;
    wire [7:0] #1 q;
    wire [7:0] q_2;

    register_8it u1_register_8it (
        .clk(clk),
        .rst_n(rst_n),
        .d(d),
        .q(q)
    );

    register_8it_2 u1_register_8it_2 (
        .clk(clk),
        .rst_n(rst_n),
        .d(d),
        .q(q_2)
    );

    integer i;

    always #5 clk = ~clk;
    initial begin
        clk   = 0;
        rst_n = 0;
        repeat (5) @(posedge clk);
        rst_n = 1;

        #1;
        for (i = 0; i < 256; i = i + 1) begin
            d = i;
            #10;
        end

        $finish;
    end

endmodule
