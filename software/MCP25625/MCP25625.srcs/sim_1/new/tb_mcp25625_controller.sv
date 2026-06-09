
`timescale 1ns / 1ps

module tb_mcp25625_controller;

    logic clk;
    logic rst_n;

    logic INT;
    logic CS;

    logic [10:0] rx_id;
    logic [3:0]  rx_dlc;
    logic [7:0]  rx_data0, rx_data1, rx_data2, rx_data3;
    logic [7:0]  rx_data4, rx_data5, rx_data6, rx_data7;

    logic rx_ready;
    logic rx_valid;

    logic [10:0] tx_id;
    logic [3:0]  tx_dlc;
    logic [7:0]  tx_data0, tx_data1, tx_data2, tx_data3;
    logic [7:0]  tx_data4, tx_data5, tx_data6, tx_data7;

    logic tx_request;
    logic tx_busy;

    logic [7:0] spi_tx_data;
    logic [7:0] spi_rx_data;
    logic       spi_request;
    logic       spi_done;

    // DUT
    mcp25625_controller dut (
        .clk(clk),
        .rst_n(rst_n),

        .INT(INT),
        .CS(CS),

        .rx_id(rx_id),
        .rx_dlc(rx_dlc),
        .rx_data0(rx_data0),
        .rx_data1(rx_data1),
        .rx_data2(rx_data2),
        .rx_data3(rx_data3),
        .rx_data4(rx_data4),
        .rx_data5(rx_data5),
        .rx_data6(rx_data6),
        .rx_data7(rx_data7),

        .rx_ready(rx_ready),
        .rx_valid(rx_valid),

        .tx_id(tx_id),
        .tx_dlc(tx_dlc),
        .tx_data0(tx_data0),
        .tx_data1(tx_data1),
        .tx_data2(tx_data2),
        .tx_data3(tx_data3),
        .tx_data4(tx_data4),
        .tx_data5(tx_data5),
        .tx_data6(tx_data6),
        .tx_data7(tx_data7),

        .tx_request(tx_request),
        .tx_busy(tx_busy),

        .spi_tx_data(spi_tx_data),
        .spi_rx_data(spi_rx_data),
        .spi_request(spi_request),
        .spi_done(spi_done)
    );

    // clock
    initial clk = 0;
    always #5 clk = ~clk; // 100 MHz

    // ---------------------------------------------------------
    // Simple fake SPI slave response
    // ---------------------------------------------------------
    int byte_cnt;
    logic [7:0] cmd;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            spi_done    <= 1'b0;
            spi_rx_data <= 8'h00;
            byte_cnt    <= 0;
            cmd         <= 8'h00;
        end else begin
            spi_done <= 1'b0;

            if (CS) begin
                byte_cnt <= 0;
                cmd      <= 8'h00;
            end

            if (spi_request) begin
                spi_done <= 1'b1;

                if (byte_cnt == 0)
                    cmd <= spi_tx_data;

                // default response
                spi_rx_data <= 8'h00;

                // READ STATUS 0xA0
                // byte1에서 status 반환
                if (cmd == 8'hA0 || spi_tx_data == 8'hA0) begin
                    if (byte_cnt == 1) begin
                        // RX0IF=1 또는 TX0IF=1 상황 가정
                        spi_rx_data <= 8'b0000_1001;
                        // bit0 RX0IF = 1
                        // bit3 TX0IF = 1
                    end
                end

                // READ register 0x03, RXB0SIDH start 0x61
                if (cmd == 8'h03) begin
                    case (byte_cnt)
                        2:  spi_rx_data <= 8'h24; // SIDH for ID 0x123
                        3:  spi_rx_data <= 8'h60; // SIDL for ID 0x123
                        4:  spi_rx_data <= 8'h00; // EID8
                        5:  spi_rx_data <= 8'h00; // EID0
                        6:  spi_rx_data <= 8'h08; // DLC
                        7:  spi_rx_data <= 8'h11;
                        8:  spi_rx_data <= 8'h22;
                        9:  spi_rx_data <= 8'h33;
                        10: spi_rx_data <= 8'h44;
                        11: spi_rx_data <= 8'h55;
                        12: spi_rx_data <= 8'h66;
                        13: spi_rx_data <= 8'h77;
                        14: spi_rx_data <= 8'h88;
                        default: spi_rx_data <= 8'h00;
                    endcase
                end

                byte_cnt <= byte_cnt + 1;
            end
        end
    end

    // ---------------------------------------------------------
    // stimulus
    // ---------------------------------------------------------
    initial begin
        rst_n = 0;
        INT = 1;

        rx_ready = 0;
        tx_request = 0;

        tx_id = 11'h123;
        tx_dlc = 4'd8;
        tx_data0 = 8'h11;
        tx_data1 = 8'h22;
        tx_data2 = 8'h33;
        tx_data3 = 8'h44;
        tx_data4 = 8'h55;
        tx_data5 = 8'h66;
        tx_data6 = 8'h77;
        tx_data7 = 8'h88;

        #100;
        rst_n = 1;

        // INIT 시간 대기
        #5000;

        // RX interrupt 발생 가정
        INT = 0;

        wait(rx_valid == 1);
        #20;

        $display("RX VALID!");
        $display("rx_id   = %h", rx_id);
        $display("rx_dlc  = %h", rx_dlc);
        $display("rx_data = %h %h %h %h %h %h %h %h",
                 rx_data0, rx_data1, rx_data2, rx_data3,
                 rx_data4, rx_data5, rx_data6, rx_data7);

        rx_ready = 1;
        #20;
        rx_ready = 0;

        // interrupt clear 후 INT high 복귀 가정
        INT = 1;

        #1000;

        // TX request test
        tx_request = 1;
        #10;
        tx_request = 0;

        #5000;

        $finish;
    end

endmodule