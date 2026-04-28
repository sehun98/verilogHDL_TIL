`timescale 1ns / 1ps

module tb_ram62256;
    reg       clk;
    reg [3:0] addr;
    reg [7:0] w_data;
    reg       w_e;
    wire  [7:0] r_data;

ram62256 u1_ram62256 (
    .clk(clk),
    .addr(addr),
    .w_data(w_data),
    .r_data(r_data),
    .w_e(w_e)
);

    integer i;

    // 0~16

    always #5 clk = ~clk;
    initial begin
        clk   = 0;
        addr = 0;
        w_data = 0;
        w_e = 0;
        repeat (5) @(posedge clk);
        // write 
        w_e = 1;

        @(negedge clk);        
        addr = 10;
        w_data = 8'h0a;

        @(negedge clk);        
        addr = 11;
        w_data = 8'h0b;

        @(negedge clk);        
        addr = 14;
        w_data = 8'h0c;

        @(negedge clk);        
        addr = 15;
        w_data = 8'h0d;

        @(negedge clk);   
        // read 
        w_e = 0;
        @(negedge clk);        
        addr = 10;

        @(negedge clk);        
        addr = 11;

        @(negedge clk);        
        addr = 14;

        @(negedge clk);        
        addr = 15;

        #10;

        $finish;
    end

endmodule
