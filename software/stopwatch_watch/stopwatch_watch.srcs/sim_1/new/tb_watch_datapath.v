`timescale 1ns / 1ps

module tb_watch_datapath;
    reg clk;
    reg rst_n;

    reg set_mode;
    reg up;
    reg down;
    reg [2:0] digit_sel;
    
    wire [6:0] msec;
    wire [5:0] sec;
    wire [5:0] min;
    wire [4:0] hour;

watch_datapath u1_watch_datapath (
    .clk(clk),
    .rst_n(rst_n),
    .set_mode(set_mode),
    .up(up),
    .down(down),
    .digit_sel(digit_sel),
    .msec(msec),
    .sec(sec),
    .min(min),
    .hour(hour)
);

always #5 clk = ~clk;

initial begin
    
end


endmodule
