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

    task reset_dut();
        begin
            clk         = 1'b0;
            rst_n       = 1'b0;
            SPI_CR      = 32'd0;
            SPI_TX_DATA = 32'd0;
            spi_miso    = 1'b0;

            repeat (5) @(posedge clk);
            rst_n = 1'b1;
            repeat (5) @(posedge clk);
        end
    endtask

    task start_spi(
        input [7:0] tx_data,
        input [2:0] br,
        input       cpol,
        input       cpha
    );
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

    task automatic get_edges(
        input  logic cpol,
        output string sample_edge,
        output string shift_edge
    );
        begin
            if (cpol == 1'b0) begin
                sample_edge = "posedge";
                shift_edge  = "negedge";
            end else begin
                sample_edge = "negedge";
                shift_edge  = "posedge";
            end
        end
    endtask

    task automatic drive_miso(
        input [7:0] rx_data,
        input       cpol,
        input       cpha
    );
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
                if (cpol == 1'b0) begin
                    @(negedge spi_sclk);
                end else begin
                    @(posedge spi_sclk);
                end

                spi_miso = rx_data[i];
                i = i - 1;
            end
        end
    endtask

    task automatic check_mosi(
        input [7:0] tx_data,
        input       cpol,
        input       cpha
    );
        integer i;
        begin
            wait (spi_cs == 1'b0);

            if (cpha == 1'b0) begin
                #1;
                if (spi_mosi !== tx_data[7]) begin
                    $error("[MOSI FAIL] first bit expected=%b actual=%b",
                           tx_data[7], spi_mosi);
                end
                i = 6;
            end else begin
                i = 7;
            end

            while (i >= 0) begin
                if (cpol == 1'b0) begin
                    @(negedge spi_sclk);
                end else begin
                    @(posedge spi_sclk);
                end

                #1;
                if (spi_mosi !== tx_data[i]) begin
                    $error("[MOSI FAIL] bit[%0d] expected=%b actual=%b",
                           i, tx_data[i], spi_mosi);
                end else begin
                    $display("[MOSI PASS] bit[%0d] = %b", i, spi_mosi);
                end

                i = i - 1;
            end
        end
    endtask

    task automatic wait_transfer_done();
        begin
            wait (SPI_SR[3] == 1'b1);
            wait (SPI_SR[3] == 1'b0);
            repeat (5) @(posedge clk);
        end
    endtask

    task automatic run_spi_mode_test(
        input [1:0] mode,
        input [7:0] tx_data,
        input [7:0] rx_data
    );
        logic cpol;
        logic cpha;
        begin
            cpol = mode[1];
            cpha = mode[0];

            $display("");
            $display("====================================");
            $display(" SPI MODE %0d TEST", mode);
            $display(" CPOL=%0b, CPHA=%0b", cpol, cpha);
            $display(" TX_DATA = 0x%02h", tx_data);
            $display(" RX_DATA = 0x%02h", rx_data);
            $display("====================================");

            fork
                check_mosi(tx_data, cpol, cpha);
                drive_miso(rx_data, cpol, cpha);
                begin
                    start_spi(tx_data, 3'd2, cpol, cpha);
                    wait_transfer_done();
                end
            join

            if (SPI_RX_DATA[7:0] === rx_data) begin
                $display("[RX PASS] mode=%0d expected=0x%02h actual=0x%02h",
                         mode, rx_data, SPI_RX_DATA[7:0]);
            end else begin
                $error("[RX FAIL] mode=%0d expected=0x%02h actual=0x%02h",
                       mode, rx_data, SPI_RX_DATA[7:0]);
            end

            repeat (20) @(posedge clk);
        end
    endtask

    initial begin
        reset_dut();

        run_spi_mode_test(2'd0, 8'h4D, 8'h9D); // Mode 0
        run_spi_mode_test(2'd1, 8'hA5, 8'h3C); // Mode 1
        run_spi_mode_test(2'd2, 8'hC3, 8'h5A); // Mode 2
        run_spi_mode_test(2'd3, 8'h7E, 8'hE7); // Mode 3

        $display("");
        $display("====================================");
        $display(" ALL SPI MODE TESTS FINISHED");
        $display("====================================");

        #1000;
        $finish;
    end

endmodule