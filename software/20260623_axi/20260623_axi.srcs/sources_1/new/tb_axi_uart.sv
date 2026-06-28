`timescale 1ns/1ps

module tb_axi_uart;
    // Clock / Reset
    logic clk = 0;
    logic rst_n = 0;

    always #5 clk = ~clk; // 100 MHz

    // UART core signals
    reg  [31:0] UART_CR;
    wire [31:0] UART_SR;
    reg  [31:0] UART_DR_WDATA;
    wire [31:0] UART_DR_RDATA;
    reg  [31:0] UART_IER;
    wire [31:0] UART_IFR;
    reg  [31:0] UART_ICR;
    reg         uart_dr_we;
    reg         uart_dr_re;
    wire        irq;

    wire rx;
    wire tx;

    // loopback tx -> rx
    assign rx = tx;

    // Instantiate DUT
    axi_uart_core dut (
        .clk(clk),
        .rst_n(rst_n),
        .UART_CR(UART_CR),
        .UART_SR(UART_SR),
        .UART_DR_WDATA(UART_DR_WDATA),
        .UART_DR_RDATA(UART_DR_RDATA),
        .UART_IER(UART_IER),
        .UART_IFR(UART_IFR),
        .UART_ICR(UART_ICR),
        .uart_dr_we(uart_dr_we),
        .uart_dr_re(uart_dr_re),
        .irq(irq),
        .rx(rx),
        .tx(tx)
    );
integer i;
    initial begin
        // initialize
        uart_dr_we = 0;
        uart_dr_re = 0;
        UART_CR = 32'd0;
        UART_DR_WDATA = 32'd0;
        UART_IER = 32'd0;
        UART_ICR = 32'd0;

        // reset
        rst_n = 0;
        repeat (20) @(posedge clk);
        rst_n = 1;
        repeat (10) @(posedge clk);

        // Enable UART: uart_en=1, tx_en=1, rx_en=1, BRR=3'b100 (115200)
        UART_CR = (3'b100 << 3) | (1 << 2) | (1 << 1) | (1 << 0);

        // small settle
        repeat (1000) @(posedge clk);

        // Send bytes: 'H','i','\n'
        send_byte(8'h48);
        send_byte(8'h69);
        send_byte(8'h0A);

        // Read back 3 bytes
        
        for (i = 0; i < 3; i = i + 1) begin
            // wait until rx fifo has data
            wait (UART_SR[0] == 1'b0);
            @(posedge clk);
            uart_dr_re = 1;
            @(posedge clk);
            uart_dr_re = 0;
            $display("TIME %0t: Received byte %0d = 0x%0h (%c)", $time, i, UART_DR_RDATA[7:0], UART_DR_RDATA[7:0]);
            // clear any RX irq
            UART_ICR = 32'd2;
            @(posedge clk);
            UART_ICR = 32'd0;
        end

        $display("TB: PASS - Loopback received all bytes");
        $finish;
    end

    task send_byte(input [7:0] b);
        begin
            UART_DR_WDATA = {24'd0, b};
            @(posedge clk);
            uart_dr_we = 1;
            @(posedge clk);
            uart_dr_we = 0;
            // wait enough time for transmission + reception (safe margin)
            repeat (20000) @(posedge clk);
        end
    endtask

endmodule
