`timescale 1ns / 1ps

module tb_i2c_slave_eeprom;

    logic clk;
    logic rst_n;
    logic [2:0] chip_select;
    logic scl;

    tri1  sda;
    logic sda_drv;   // 0: drive low, 1: release

    assign sda = (sda_drv == 1'b0) ? 1'b0 : 1'bz;

    eeprom dut (
        .clk        (clk),
        .rst_n      (rst_n),
        .chip_select(chip_select),
        .scl        (scl),
        .sda        (sda)
    );

    localparam CLK_PERIOD = 10;
    localparam I2C_HALF   = 2500;

    always #(CLK_PERIOD / 2) clk = ~clk;

    task i2c_start;
        begin
            sda_drv = 1'b1;
            if (scl == 1'b0)
                #(I2C_HALF);

            scl     = 1'b1;
            #(I2C_HALF);

            sda_drv = 1'b0;
            #(I2C_HALF);

            scl = 1'b0;
            #(I2C_HALF);
        end
    endtask

    task i2c_stop;
        begin
            scl     = 1'b0;
            sda_drv = 1'b0;
            #(I2C_HALF);

            scl = 1'b1;
            #(I2C_HALF);

            sda_drv = 1'b1;
            #(I2C_HALF);
        end
    endtask

    task i2c_write_bit(input logic bit_data);
        begin
            scl     = 1'b0;
            sda_drv = bit_data;   // 1이면 release
            #(I2C_HALF);

            scl = 1'b1;
            #(I2C_HALF);

            scl = 1'b0;
        end
    endtask

    task i2c_read_bit(output logic bit_data);
        begin
            scl     = 1'b0;
            sda_drv = 1'b1;       // release
            #(I2C_HALF);

            scl = 1'b1;
            #(I2C_HALF / 2);
            bit_data = sda;
            #(I2C_HALF / 2);

            scl = 1'b0;
        end
    endtask

    task i2c_write_byte(input logic [7:0] data, output logic ack);
        integer i;
        begin
            for (i = 7; i >= 0; i = i - 1) begin
                i2c_write_bit(data[i]);
            end

            // ACK bit
            scl     = 1'b0;
            sda_drv = 1'b1;       // release for slave ACK
            #(I2C_HALF);

            scl = 1'b1;
            #(I2C_HALF / 2);
            ack = (sda == 1'b0);
            #(I2C_HALF / 2);

            scl = 1'b0;
        end
    endtask

    task i2c_read_byte(output logic [7:0] data, input logic master_ack);
        integer i;
        begin
            sda_drv = 1'b1;

            for (i = 7; i >= 0; i = i - 1) begin
                i2c_read_bit(data[i]);
            end

            if (master_ack)
                i2c_write_bit(1'b0);   // ACK
            else
                i2c_write_bit(1'b1);   // NACK
        end
    endtask

    task eeprom_write_byte(
        input logic [2:0] dev_sel,
        input logic [7:0] mem_addr,
        input logic [7:0] data
    );
        logic ack;
        logic [7:0] slave_addr;
        begin
            slave_addr = {4'b1010, dev_sel, 1'b0};

            i2c_start();

            i2c_write_byte(slave_addr, ack);
            if (!ack) $display("[FAIL] slave write address ACK fail");

            i2c_write_byte(mem_addr, ack);
            if (!ack) $display("[FAIL] memory address ACK fail");

            i2c_write_byte(data, ack);
            if (!ack) $display("[FAIL] write data ACK fail");

            i2c_stop();

            $display("[WRITE] mem_addr=0x%02h, data=0x%02h", mem_addr, data);
        end
    endtask

    task eeprom_read_byte(
        input  logic [2:0] dev_sel,
        input  logic [7:0] mem_addr,
        output logic [7:0] data
    );
        logic ack;
        logic [7:0] slave_addr_w;
        logic [7:0] slave_addr_r;
        begin
            slave_addr_w = {4'b1010, dev_sel, 1'b0};
            slave_addr_r = {4'b1010, dev_sel, 1'b1};

            // dummy write: set memory address
            i2c_start();

            i2c_write_byte(slave_addr_w, ack);
            if (!ack) $display("[FAIL] slave write address ACK fail");

            i2c_write_byte(mem_addr, ack);
            if (!ack) $display("[FAIL] memory address ACK fail");

            // repeated start
            i2c_start();

            i2c_write_byte(slave_addr_r, ack);
            if (!ack) $display("[FAIL] slave read address ACK fail");

            i2c_read_byte(data, 1'b0); // NACK after 1 byte

            i2c_stop();

            $display("[READ ] mem_addr=0x%02h, data=0x%02h", mem_addr, data);
        end
    endtask

    initial begin
        logic [7:0] rdata;

        clk         = 1'b0;
        rst_n       = 1'b0;
        chip_select = 3'b000;
        scl         = 1'b1;
        sda_drv     = 1'b1;

        repeat (10) @(posedge clk);
        rst_n = 1'b1;
        repeat (20) @(posedge clk);

        eeprom_write_byte(3'b000, 8'h10, 8'hA5);
        #(I2C_HALF * 4);

        eeprom_read_byte(3'b000, 8'h10, rdata);

        if (rdata == 8'hA5)
            $display("[PASS] EEPROM read/write test passed");
        else
            $display("[FAIL] expected=0xA5, actual=0x%02h", rdata);
        eeprom_write_byte(3'b000, 8'h11, 8'hA5);
        #(I2C_HALF * 4);

        eeprom_read_byte(3'b000, 8'h11, rdata);

        
        eeprom_write_byte(3'b000, 8'h12, 8'hA5);
        eeprom_write_byte(3'b000, 8'h13, 8'hA5);
        eeprom_write_byte(3'b000, 8'h14, 8'hA5);
        eeprom_write_byte(3'b000, 8'h15, 8'hA5);
        
        #(I2C_HALF * 4);

        eeprom_read_byte(3'b000, 8'h13, rdata);
        #(I2C_HALF * 10);
        $finish;
    end

endmodule
