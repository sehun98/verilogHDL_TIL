`timescale 1ns / 1ps

module tb_ram_single;
    reg clk;
    reg we;
    reg [7:0] waddr;
    reg [7:0] wdata;
    reg [7:0] raddr;
    wire [7:0] rdata;

    ram_single u1_ram_single (
        .clk(clk),
        .we(we),
        .waddr(waddr),
        .wdata(wdata),
        .raddr(raddr),
        .rdata(rdata)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        we = 0;
        waddr = 0;
        wdata = 0;
        raddr = 0;
    end

    // -------------------------------
    // Scenalio 1 : 
    // 
    // -------------------------------

    initial begin
        
    end
endmodule
