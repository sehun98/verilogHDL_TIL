`timescale 1ns / 1ps

module tb_sck_generator;
    reg  clk;
    reg  rst_n;
    wire sck_square;
    wire sck_rising_tick;
    wire sck_falling_tick;

    spi_generator #(
        .CLOCK_FREQ_HZ(100_000_000),
        .SCK_FREQ_HZ  (100_000)
    ) u1_spi_generator (
        .clk(clk),
        .rst_n(rst_n),
        .sck_square(sck_square),
        .sck_rising_tick(sck_rising_tick),
        .sck_falling_tick(sck_falling_tick)
    );

    always #5 clk = ~clk;

    initial begin
        clk   = 0;
        rst_n = 0;
        repeat (5) @(posedge clk);

        rst_n = 1;

        #1000_000;
        $finish;
    end

endmodule
