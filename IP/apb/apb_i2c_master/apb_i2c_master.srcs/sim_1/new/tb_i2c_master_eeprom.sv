`timescale 1ns / 1ps

module tb_i2c_master_eeprom;

    logic clk;
    logic reset;

    logic cmd_start;
    logic cmd_write;
    logic cmd_read;
    logic cmd_stop;

    logic [7:0] tx_data;
    logic [7:0] rx_data;
    logic       ack_in;
    logic       ack_out;
    logic       busy;
    logic       done;

    logic scl;
    wire  sda;

    logic [2:0] chip_select;

    // pull-up: I2C SDA는 open-drain이라 필요
    pullup(sda);

    // clock
    initial clk = 0;
    always #5 clk = ~clk;   // 100MHz

    // DUT: I2C Master
    i2c_master_top u_master (
        .clk       (clk),
        .reset     (reset),

        .cmd_start (cmd_start),
        .cmd_write (cmd_write),
        .cmd_read  (cmd_read),
        .cmd_stop  (cmd_stop),

        .tx_data   (tx_data),
        .rx_data   (rx_data),
        .ack_in    (ack_in),
        .ack_out   (ack_out),
        .busy      (busy),
        .done      (done),

        .scl       (scl),
        .sda       (sda)
    );

    // DUT: I2C EEPROM Slave
    eeprom u_eeprom (
        .clk         (clk),
        .rst_n       (~reset),
        .chip_select (chip_select),
        .scl         (scl),
        .sda         (sda)
    );

    // -----------------------------
    // command task
    // -----------------------------
    task automatic wait_done();
        begin
            wait(done == 1'b1);
            @(posedge clk);
            wait(done == 1'b0);
        end
    endtask

    task automatic i2c_start();
        begin
            @(posedge clk);
            cmd_start <= 1'b1;
            @(posedge clk);
            cmd_start <= 1'b0;
            wait_done();
        end
    endtask

    task automatic i2c_stop();
        begin
            @(posedge clk);
            cmd_stop <= 1'b1;
            @(posedge clk);
            cmd_stop <= 1'b0;
            wait_done();
        end
    endtask

    task automatic i2c_write(input logic [7:0] data);
        begin
            @(posedge clk);
            tx_data   <= data;
            cmd_write <= 1'b1;
            @(posedge clk);
            cmd_write <= 1'b0;
            wait_done();

            if (ack_out == 1'b0)
                $display("[I2C WRITE ACK] data = %02h", data);
            else
                $display("[I2C WRITE NACK] data=%02h slave_state=%0d addr_rw=%02h",
                         data, u_eeprom.u1_i2c_slave_eeprom.state,
                         u_eeprom.u1_i2c_slave_eeprom.addr_rw);
        end
    endtask

    task automatic i2c_read(input logic master_ack);
        begin
            @(posedge clk);
            ack_in   <= master_ack;   // 0: ACK, 1: NACK 구조면 여기 맞춰 수정
            cmd_read <= 1'b1;
            @(posedge clk);
            cmd_read <= 1'b0;
            wait_done();

            $display("[I2C READ] rx_data = %02h", rx_data);
        end
    endtask

    // -----------------------------
    // test scenario
    // -----------------------------
    initial begin
        #2_000_000;
        $fatal(1, "Timeout: EEPROM transaction did not finish");
    end

    initial begin
        reset       = 1'b1;
        cmd_start   = 1'b0;
        cmd_write   = 1'b0;
        cmd_read    = 1'b0;
        cmd_stop    = 1'b0;
        tx_data     = 8'h00;
        ack_in      = 1'b0;
        chip_select = 3'b000;

        repeat (10) @(posedge clk);
        reset = 1'b0;

        repeat (10) @(posedge clk);

        // ----------------------------------
        // EEPROM WRITE
        // START
        // DEVICE_ADDR + W
        // MEM_ADDR
        // DATA
        // STOP
        // ----------------------------------
        $display("========== EEPROM WRITE TEST ==========");

        i2c_start();

        // 24Cxx 기준: 1010 + chip_select[2:0] + R/W
        // chip_select = 000, write = 0
        i2c_write(8'b1010_0000);   // slave address + write

        i2c_write(8'h10);          // memory address
        i2c_write(8'hA5);          // write data

        i2c_stop();

        repeat (1000) @(posedge clk);

        // ----------------------------------
        // EEPROM READ
        // START
        // DEVICE_ADDR + W
        // MEM_ADDR
        // RESTART
        // DEVICE_ADDR + R
        // READ DATA
        // STOP
        // ----------------------------------
        $display("========== EEPROM READ TEST ==========");

        i2c_start();

        i2c_write(8'b1010_0000);   // slave address + write
        i2c_write(8'h10);          // memory address

        i2c_start();               // repeated start

        i2c_write(8'b1010_0001);   // slave address + read

        i2c_read(1'b1);            // 마지막 1바이트 read 후 NACK

        if (rx_data !== 8'hA5)
            $fatal(1, "EEPROM read mismatch: expected A5, got %02h", rx_data);

        i2c_stop();

        repeat (1000) @(posedge clk);

        $display("========== TEST PASS ==========");
        $finish;
    end

endmodule
