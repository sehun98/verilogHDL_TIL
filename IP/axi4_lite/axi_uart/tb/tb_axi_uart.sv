`timescale 1ns / 1ps

module tb_axi_uart;
    localparam integer CLK_FREQ_HZ = 100_000_000;
    localparam integer BAUD_RATE = 115_200;
    localparam integer BIT_CYCLES = (CLK_FREQ_HZ + (BAUD_RATE / 2)) / BAUD_RATE;

    localparam logic [4:0] UART_CR = 5'h00;
    localparam logic [4:0] UART_SR = 5'h04;
    localparam logic [4:0] UART_BRR = 5'h08;
    localparam logic [4:0] UART_DR = 5'h0C;
    localparam logic [4:0] UART_IER = 5'h10;
    localparam logic [4:0] UART_IFR = 5'h14;
    localparam logic [4:0] UART_ICR = 5'h18;

    logic          clk;
    logic          rst_n;
    logic   [ 4:0] awaddr;
    logic   [ 2:0] awprot;
    logic          awvalid;
    wire           awready;
    logic   [31:0] wdata;
    logic   [ 3:0] wstrb;
    logic          wvalid;
    wire           wready;
    wire    [ 1:0] bresp;
    wire           bvalid;
    logic          bready;
    logic   [ 4:0] araddr;
    logic   [ 2:0] arprot;
    logic          arvalid;
    wire           arready;
    wire    [31:0] rdata;
    wire    [ 1:0] rresp;
    wire           rvalid;
    logic          rready;
    wire           tx;
    wire           rx;
    wire           irq;
    logic          loopback_en;
    logic          rx_drive;

    integer        error_count;
    logic   [31:0] read_data;

    assign rx = loopback_en ? tx : rx_drive;

    axi_uart_v1_0 #(
        .C_UART_CLK_FREQ_HZ(CLK_FREQ_HZ)
    ) dut (
        .rx             (rx),
        .tx             (tx),
        .irq            (irq),
        .s00_axi_aclk   (clk),
        .s00_axi_aresetn(rst_n),
        .s00_axi_awaddr (awaddr),
        .s00_axi_awprot (awprot),
        .s00_axi_awvalid(awvalid),
        .s00_axi_awready(awready),
        .s00_axi_wdata  (wdata),
        .s00_axi_wstrb  (wstrb),
        .s00_axi_wvalid (wvalid),
        .s00_axi_wready (wready),
        .s00_axi_bresp  (bresp),
        .s00_axi_bvalid (bvalid),
        .s00_axi_bready (bready),
        .s00_axi_araddr (araddr),
        .s00_axi_arprot (arprot),
        .s00_axi_arvalid(arvalid),
        .s00_axi_arready(arready),
        .s00_axi_rdata  (rdata),
        .s00_axi_rresp  (rresp),
        .s00_axi_rvalid (rvalid),
        .s00_axi_rready (rready)
    );

    always #5 clk = ~clk;

    task automatic axi_write(input logic [4:0] addr, input logic [31:0] data);
        begin
            @(negedge clk);
            awaddr  = addr;
            awvalid = 1'b1;
            wdata   = data;
            wstrb   = 4'hF;
            wvalid  = 1'b1;

            do @(posedge clk); while (!(awready && wready));

            @(negedge clk);
            awvalid = 1'b0;
            wvalid  = 1'b0;

            do @(posedge clk); while (!bvalid);
            if (bresp != 2'b00) begin
                $error("AXI write response error: addr=%02h bresp=%02b", addr,
                       bresp);
                error_count = error_count + 1;
            end

            @(negedge clk);
        end
    endtask

    task automatic axi_read(input logic [4:0] addr, output logic [31:0] data);
        begin
            @(negedge clk);
            araddr  = addr;
            arvalid = 1'b1;

            do @(posedge clk); while (!arready);

            @(negedge clk);
            arvalid = 1'b0;

            do @(posedge clk); while (!rvalid);
            data = rdata;
            if (rresp != 2'b00) begin
                $error("AXI read response error: addr=%02h rresp=%02b", addr,
                       rresp);
                error_count = error_count + 1;
            end

            @(negedge clk);
        end
    endtask

    task automatic expect_bit(input logic [31:0] value, input integer i,
                              input logic expected, input string message);
        begin
            if (value[i] !== expected) begin
                $error("%s: value=%08h bit[%0d]=%b expected=%b", message,
                       value, i, value[i], expected);
                error_count = error_count + 1;
            end
        end
    endtask

    task automatic wait_irq(input logic expected, input integer max_cycles,
                            input string message);
        integer cycle;
        begin
            cycle = 0;
            while ((irq !== expected) && (cycle < max_cycles)) begin
                @(posedge clk);
                cycle = cycle + 1;
            end

            if (irq !== expected) begin
                $error("%s: irq=%b after %0d cycles", message, irq, max_cycles);
                error_count = error_count + 1;
            end
        end
    endtask

    task automatic uart_send_to_rx(input logic [7:0] data,
                                   input logic stop_bit);
        integer i;
        begin
            @(negedge clk);
            rx_drive = 1'b0;
            repeat (BIT_CYCLES) @(posedge clk);

            for (i = 0; i < 8; i = i + 1) begin
                rx_drive = data[i];
                repeat (BIT_CYCLES) @(posedge clk);
            end

            rx_drive = stop_bit;
            repeat (BIT_CYCLES) @(posedge clk);
            rx_drive = 1'b1;
        end
    endtask

    task automatic uart_capture_tx(output logic [7:0] data);
        integer i;
        begin
            data = 8'd0;
            wait (tx === 1'b1);
            @(negedge tx);

            repeat (BIT_CYCLES / 2) @(posedge clk);
            if (tx !== 1'b0) begin
                $error("TX start bit is not low");
                error_count = error_count + 1;
            end

            for (i = 0; i < 8; i = i + 1) begin
                repeat (BIT_CYCLES) @(posedge clk);
                data[i] = tx;
            end

            repeat (BIT_CYCLES) @(posedge clk);
            if (tx !== 1'b1) begin
                $error("TX stop bit is not high");
                error_count = error_count + 1;
            end
        end
    endtask

    initial begin
        clk         = 1'b0;
        rst_n       = 1'b0;
        awaddr      = 5'd0;
        awprot      = 3'd0;
        awvalid     = 1'b0;
        wdata       = 32'd0;
        wstrb       = 4'd0;
        wvalid      = 1'b0;
        bready      = 1'b1;
        araddr      = 5'd0;
        arprot      = 3'd0;
        arvalid     = 1'b0;
        rready      = 1'b1;
        loopback_en = 1'b1;
        rx_drive    = 1'b1;
        error_count = 0;

        repeat (5) @(posedge clk);
        rst_n = 1'b1;
        repeat (2) @(posedge clk);

        // UART_BRR contains the requested baud rate.
        axi_write(UART_BRR, BAUD_RATE);
        axi_write(UART_CR, 32'h0000_0007);

        axi_read(UART_SR, read_data);
        expect_bit(read_data, 0, 1'b1, "RX FIFO must be empty after reset");
        expect_bit(read_data, 4, 1'b1, "TX must initially be complete");

        // Enable RX interrupt and transmit one byte through the loopback.
        axi_write(UART_IER, 32'h0000_0002);
        axi_write(UART_DR, 32'h0000_00A5);

        wait_irq(1'b1, BIT_CYCLES * 12, "RX interrupt was not asserted");

        axi_read(UART_IFR, read_data);
        expect_bit(read_data, 1, 1'b1, "RX interrupt flag must be set");

        axi_read(UART_DR, read_data);
        if (read_data[7:0] !== 8'hA5) begin
            $error("Loopback data mismatch: received=%02h expected=A5",
                   read_data[7:0]);
            error_count = error_count + 1;
        end

        wait_irq(1'b0, 10,
                 "RX interrupt did not clear after FIFO became empty");

        repeat (BIT_CYCLES * 2) @(posedge clk);
        axi_read(UART_SR, read_data);
        expect_bit(read_data, 0, 1'b1, "RX FIFO must be empty after DR read");
        expect_bit(read_data, 4, 1'b1,
                   "TX must be complete after loopback byte");

        // TX completion is sticky and cleared by writing one to ICR[0].
        axi_write(UART_IER, 32'h0000_0001);
        wait_irq(1'b1, BIT_CYCLES * 2,
                 "TX completion interrupt was not asserted");

        axi_read(UART_IFR, read_data);
        expect_bit(read_data, 0, 1'b1, "TX interrupt flag must be set");

        axi_write(UART_ICR, 32'h0000_0001);
        wait_irq(1'b0, 10, "TX interrupt did not clear after ICR write");

        // Independent RX test: drive the RX pin from the testbench.
        $display("[%0t] Starting independent RX test", $time);
        loopback_en = 1'b0;
        axi_write(UART_IER, 32'h0000_0002);
        fork
            uart_send_to_rx(8'h3C, 1'b1);
            begin
                wait_irq(1'b1, BIT_CYCLES * 12,
                         "External RX interrupt was not asserted");
                axi_read(UART_DR, read_data);
                if (read_data[7:0] !== 8'h3C) begin
                    $error("External RX mismatch: received=%02h expected=3C",
                           read_data[7:0]);
                    error_count = error_count + 1;
                end
                wait_irq(1'b0, 10, "External RX interrupt did not clear");
            end
        join

        // Framing error must remain set until ICR[4] is written.
        $display("[%0t] Starting framing error test", $time);
        fork
            uart_send_to_rx(8'h55, 1'b0);
        join
        repeat (BIT_CYCLES) @(posedge clk);
        axi_read(UART_SR, read_data);
        expect_bit(read_data, 8, 1'b1, "Frame error flag must be sticky");
        axi_write(UART_ICR, 32'h0000_0010);
        axi_read(UART_SR, read_data);
        expect_bit(read_data, 8, 1'b0, "Frame error flag did not clear");

        // Independent TX test: decode the TX pin without loopback.
        $display("[%0t] Starting independent TX test", $time);
        axi_write(UART_CR, 32'h0000_0006);
        axi_write(UART_ICR, 32'h0000_0001);
        axi_write(UART_IER, 32'h0000_0001);
        fork
            begin
                uart_capture_tx(read_data[7:0]);
            end
            begin
                axi_write(UART_DR, 32'h0000_005A);
            end
        join

        if (read_data[7:0] !== 8'h5A) begin
            $error("Independent TX mismatch: captured=%02h expected=5A",
                   read_data[7:0]);
            error_count = error_count + 1;
        end
        wait_irq(1'b1, BIT_CYCLES * 2,
                 "Independent TX interrupt was not asserted");
        axi_write(UART_ICR, 32'h0000_0001);
        wait_irq(1'b0, 10, "Independent TX interrupt did not clear");

        if (error_count == 0) begin
            $display("PASS: AXI UART loopback and interrupt test completed");
        end else begin
            $fatal(1, "FAIL: AXI UART test detected %0d error(s)", error_count);
        end

        #100;
        $finish;
    end

    initial begin
        #1_000_000;
        $fatal(1, "FAIL: simulation timeout");
    end
endmodule
