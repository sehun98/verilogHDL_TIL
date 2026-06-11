`timescale 1ns / 1ps

module tb_spi_master;

    logic clk;
    logic rst_n;

    logic [31:0] SPI_CR;
    logic [31:0] SPI_SR;
    logic [31:0] SPI_TX_DATA;
    logic [31:0] SPI_RX_DATA;

    logic spi_sclk;
    logic spi_mosi;
    logic spi_miso;
    logic spi_cs;

    spi_master dut (
        .clk        (clk),
        .rst_n      (rst_n),
        .SPI_CR     (SPI_CR),
        .SPI_SR     (SPI_SR),
        .SPI_TX_DATA(SPI_TX_DATA),
        .SPI_RX_DATA(SPI_RX_DATA),
        .spi_sclk   (spi_sclk),
        .spi_mosi   (spi_mosi),
        .spi_miso   (spi_miso),
        .spi_cs     (spi_cs)
    );

    always #5 clk = ~clk;
    task automatic start_spi(input [7:0] tx_data, input [2:0] br, input cpol,
                             input cpha);
        begin
            SPI_TX_DATA = tx_data;

            SPI_CR[4:2] = br;
            SPI_CR[1]   = cpol;
            SPI_CR[0]   = cpha;

            @(posedge clk);
            SPI_CR[5] = 1'b1;
            @(posedge clk);
            SPI_CR[5] = 1'b0;
        end
    endtask
    task automatic run_one_mode(input [1:0] mode, input [7:0] tx_data,
                                input [7:0] rx_data);
        logic cpol;
        logic cpha;
        begin
            cpol = mode[1];
            cpha = mode[0];

            $display("MODE %0d START", mode);

            start_spi(tx_data, 3'd2, cpol, cpha);
            drive_miso(rx_data, cpol, cpha);

            wait (SPI_SR[1] == 1'b1);  // rx_done
            @(posedge clk);

            $display("MODE %0d RX = %02h", mode, SPI_RX_DATA[7:0]);

            repeat (20) @(posedge clk);
        end
    endtask
    task automatic drive_miso(input [7:0] rx_data, input cpol, input cpha);
        integer i;
        begin
            wait (spi_cs == 1'b0);

            if (cpha == 1'b0) begin
                spi_miso = rx_data[7];
                i = 6;
            end else begin
                i = 7;
            end

            while (i >= 0) begin
                if (cpol ^ cpha) @(posedge spi_sclk);
                else @(negedge spi_sclk);

                spi_miso = rx_data[i];
                i = i - 1;
            end
        end
    endtask

    initial begin
        clk         = 1'b0;
        rst_n       = 1'b0;
        SPI_CR      = 32'd0;
        SPI_TX_DATA = 32'd0;
        spi_miso    = 1'b0;

        repeat (5) @(posedge clk);
        rst_n = 1'b1;
        repeat (5) @(posedge clk);

        run_one_mode(2'd0, 8'h4D, 8'h9D);
        run_one_mode(2'd1, 8'hA5, 8'h3C);
        run_one_mode(2'd2, 8'hC3, 8'h5A);
        run_one_mode(2'd3, 8'h7E, 8'hE7);

        $finish;
    end

endmodule
