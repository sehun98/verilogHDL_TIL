`timescale 1ns / 1ps

module tb_spi_slave();

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

    spi_slave dut (
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

    task automatic spi_half_cycle(input [2:0] br);
        integer div;
        begin
            div = 4 << br;
            repeat (div) @(posedge clk);
        end
    endtask

    task automatic toggle_sclk(input [2:0] br);
        begin
            spi_half_cycle(br);
            @(negedge clk);
            spi_sclk = ~spi_sclk;
        end
    endtask

    task automatic start_spi(
        input [7:0] tx_data,
        input [2:0] br,
        input       cpol,
        input       cpha
    );
        begin
            @(negedge clk);
            SPI_TX_DATA = tx_data;

            SPI_CR[4:2] = br;
            SPI_CR[1]   = cpol;
            SPI_CR[0]   = cpha;

            spi_sclk = cpol;
            spi_cs   = 1'b1;
            spi_mosi = 1'b0;

            repeat (3) @(posedge clk);
        end
    endtask

    task automatic drive_mosi(
        input [7:0] rx_data,
        input [2:0] br,
        input       cpol,
        input       cpha
    );
        integer i;
        begin
            @(negedge clk);
            spi_sclk = cpol;
            spi_cs   = 1'b0;
            spi_mosi = 1'b0;

            repeat (2) @(posedge clk);

            if (cpha == 1'b0) begin
                @(negedge clk);
                spi_mosi = rx_data[7];
            end

            for (i = 7; i >= 0; i = i - 1) begin
                toggle_sclk(br); // leading edge

                if (cpha == 1'b1) begin
                    @(negedge clk);
                    spi_mosi = rx_data[i];
                end

                toggle_sclk(br); // trailing edge

                if (cpha == 1'b0 && i != 0) begin
                    @(negedge clk);
                    spi_mosi = rx_data[i-1];
                end
            end

            spi_half_cycle(br);

            @(negedge clk);
            spi_sclk = cpol;
            spi_cs   = 1'b1;
            spi_mosi = 1'b0;
        end
    endtask

    task automatic run_one_mode(
        input [1:0] mode,
        input [7:0] tx_data,
        input [7:0] rx_data
    );
        logic cpol;
        logic cpha;
        logic [2:0] br;
        begin
            cpol = mode[1];
            cpha = mode[0];
            br   = 3'd2;

            $display("====================================");
            $display("MODE %0d START CPOL=%0b CPHA=%0b", mode, cpol, cpha);

            start_spi(tx_data, br, cpol, cpha);

            fork
                drive_mosi(rx_data, br, cpol, cpha);

                begin
                    wait (SPI_SR[1] == 1'b1); // rx_done
                end
            join

            repeat (2) @(posedge clk);

            $display("MODE %0d RX = %02h, EXPECT = %02h",
                     mode, SPI_RX_DATA[7:0], rx_data);

            if (SPI_RX_DATA[7:0] == rx_data)
                $display("MODE %0d PASS", mode);
            else
                $display("MODE %0d FAIL", mode);

            repeat (20) @(posedge clk);
        end
    endtask

    initial begin
        clk         = 1'b0;
        rst_n       = 1'b0;
        SPI_CR      = 32'd0;
        SPI_TX_DATA = 32'd0;

        spi_sclk = 1'b0;
        spi_mosi = 1'b0;
        spi_cs   = 1'b1;

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