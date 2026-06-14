import uvm_pkg::*;
import ram_pkg::*;  //header file

module tb_spi_top ();
    logic clk;
    logic rst_n;

    initial begin
        clk   = 0;
        rst_n = 0;
        repeat(2) @(posedge clk);
        rst_n = 1;
    end
    always #5 clk = ~clk;

    spi_master_interface spi_master_if (
        .clk  (clk),
        .rst_n(rst_n)
    );

    spi_master dut (
        // global signals
        .clk    (spi_master_if.clk),
        .rst_n  (spi_master_if.rst_n),
        // internal signals
        .start  (spi_master_if.start),
        .cpol   (spi_master_if.cpol),
        .cpha   (spi_master_if.cpha),
        .clk_div(spi_master_if.clk_div),
        .tx_data(spi_master_if.master_tx_data),
        .busy   (spi_master_if.master_busy),
        .rx_data(spi_master_if.master_rx_data),
        .done   (spi_master_if.master_done),
        // external signals
        .sclk   (spi_master_if.sclk),
        .mosi   (spi_master_if.mosi),
        .miso   (spi_master_if.miso),
        .ss_n   (spi_master_if.ss_n)
    );

    initial begin
        //delay code x
        uvm_config_db#(virtual spi_master_interface)::set(
            null, "*", "spi_master_if", spi_master_if);
        run_test("spi_master_test");
    end

    initial begin
        $fsdbDumpfile("spi_master_tb.fsdb");
        $fsdbDumpvars(0);
        $fsdbDumpMDA();  //메모리 배열(mem) 덤프
    end
endmodule
