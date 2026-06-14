`timescale 1ns / 1ps

module tb_spi_regression;
    logic       clk = 1'b0;
    logic       reset;
    logic       start;
    logic [7:0] clk_div;
    logic [7:0] master_tx_data;
    logic [7:0] slave_tx_data;
    logic       cpol;
    logic       cpha;
    logic       master_done;
    logic       slave_done;
    logic [7:0] master_rx_data;
    logic [7:0] slave_rx_data;

    spi_top dut (.*);

    always #5 clk = ~clk;

    task automatic transfer(
        input logic [1:0] mode,
        input logic [7:0] master_data,
        input logic [7:0] slave_data
    );
        integer timeout;
        begin
            {cpol, cpha} = mode;
            master_tx_data = master_data;
            slave_tx_data = slave_data;

            @(posedge clk);
            start = 1'b1;
            @(posedge clk);
            start = 1'b0;

            timeout = 0;
            while (!master_done && timeout < 1000) begin
                @(posedge clk);
                timeout = timeout + 1;
            end

            if (timeout == 1000)
                $fatal(1, "mode %b timed out", mode);

            wait (slave_done);
            if (master_rx_data !== slave_data || slave_rx_data !== master_data)
                $fatal(1,
                       "mode %b failed: master_rx=%h slave_rx=%h",
                       mode, master_rx_data, slave_rx_data);

            $display("mode %b passed: master_rx=%h slave_rx=%h",
                     mode, master_rx_data, slave_rx_data);
            @(posedge clk);
        end
    endtask

    initial begin
        reset = 1'b1;
        start = 1'b0;
        clk_div = 8'd2;
        master_tx_data = 8'd0;
        slave_tx_data = 8'd0;
        cpol = 1'b0;
        cpha = 1'b0;

        repeat (3) @(posedge clk);
        reset = 1'b0;

        transfer(2'b00, 8'hAA, 8'h55);
        transfer(2'b01, 8'h7A, 8'hC3);
        transfer(2'b10, 8'h96, 8'h69);
        transfer(2'b11, 8'h0F, 8'hF0);

        $display("all SPI modes passed");
        $finish;
    end
endmodule
