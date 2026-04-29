`timescale 1ns / 1ps

module tb_spi_mode0;
    reg clk;
    reg rst_n;
    reg send;
    reg [7:0] tx_data;
    wire [7:0] rx_data;
    wire done;
    wire MOSI;
    reg MISO;
    wire CS;
    wire SCK;

    wire sck_square;
    wire sck_rising_tick;
    wire sck_falling_tick;

    localparam DEBUG_DELAY = 1000_0;

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

    spi u2_spi (
        .clk(clk),
        .rst_n(rst_n),
        .sck_square(sck_square),
        .sck_rising_tick(sck_rising_tick),
        .sck_falling_tick(sck_falling_tick),

        .send(send),
        .done(done),
        
        .tx_data(tx_data),
        .rx_data(rx_data),
        .MOSI(MOSI),
        .MISO(MISO),
        .CS(CS),
        .SCK(SCK)
    );

    always #5 clk = ~clk;

    reg [7:0] miso_data;
    integer i;

    initial begin
        clk = 0;
        rst_n = 0;
        send = 0;
        tx_data = 0;
        MISO = 0;
        miso_data = 8'h30;

        repeat (5) @(posedge clk);
        rst_n = 1;

        #(DEBUG_DELAY);
        #3;
        tx_data = 8'h30;
        send = 1;
        @(posedge clk);
        send = 0;

        // CS가 내려갈 때까지 대기
        wait (CS == 1'b0);

        // Mode 0: rising 전에 MISO가 안정되어 있어야 함
        MISO = miso_data[7];

        for (i = 6; i >= 0; i = i - 1) begin
            @(negedge SCK);
            MISO = miso_data[i];
        end

        wait (CS == 1'b1);

        $display("rx_data = %h", rx_data);

        #(DEBUG_DELAY);
        $finish;
    end

endmodule
