`timescale 1ns / 1ps

module tb_spi_master();
    logic clk;
    logic rst_n;
    logic [7:0] tx_data;
    logic [7:0] rx_data;
    logic request;
    logic done;
    logic sck;
    logic SCK;
    logic MOSI;
    logic MISO;

spi_master dut (
    .clk(clk),
    .rst_n(rst_n),
    .tx_data(tx_data),
    .rx_data(rx_data),
    .request(request),
    .done(done),
    .sck(sck),
    .SCK(SCK),
    .MOSI(MOSI),
    .MISO(MISO)
);

sck_gen#(
        .CLOCK_FREQ_HZ(100_000_000),
        .BAUD_RATE(500_000)
    ) dut_2 (
        .clk(clk), .rst_n(rst_n), .sck(sck)
    );

always #5 clk = ~clk;

initial begin
    clk = 0;
    rst_n = 0;
    tx_data = 0;
    request = 0;
    MISO = 0;
    repeat(2) @(posedge clk);
    rst_n = 1;

    @(negedge clk);
    tx_data = 8'h30;
    request = 1;
    @(posedge clk);
    request = 0;

    @(posedge done);
    @(posedge clk);
    request = 1;
    @(posedge clk);
    request = 0;


    #20_000;
    $finish();
end

endmodule
