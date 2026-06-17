`timescale 1ns / 1ps

module tb_i2c_multi_master_arbitration;

    logic clk;
    logic reset;

    // Master A command
    logic        mA_cmd_start;
    logic        mA_cmd_write;
    logic        mA_cmd_read;
    logic        mA_cmd_stop;
    logic [7:0]  mA_tx_data;
    logic [7:0]  mA_rx_data;
    logic        mA_ack_in;
    logic        mA_ack_out;
    logic        mA_busy;
    logic        mA_done;

    // Master B command
    logic        mB_cmd_start;
    logic        mB_cmd_write;
    logic        mB_cmd_read;
    logic        mB_cmd_stop;
    logic [7:0]  mB_tx_data;
    logic [7:0]  mB_rx_data;
    logic        mB_ack_in;
    logic        mB_ack_out;
    logic        mB_busy;
    logic        mB_done;

    // I2C shared open-drain bus
    wire sda_bus;
    wire scl_bus;

    pullup(sda_bus);
    pullup(scl_bus);

    // clock
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;   // 100MHz
    end

    // reset/init
    initial begin
        reset = 1'b1;

        mA_cmd_start = 1'b0;
        mA_cmd_write = 1'b0;
        mA_cmd_read  = 1'b0;
        mA_cmd_stop  = 1'b0;
        mA_tx_data   = 8'd0;
        mA_ack_in    = 1'b1;

        mB_cmd_start = 1'b0;
        mB_cmd_write = 1'b0;
        mB_cmd_read  = 1'b0;
        mB_cmd_stop  = 1'b0;
        mB_tx_data   = 8'd0;
        mB_ack_in    = 1'b1;

        repeat (5) @(posedge clk);
        #1000;
        reset = 1'b0;
    end

    // Master A
    i2c_master u1_i2c_master (
        .clk       (clk),
        .reset     (reset),

        .cmd_start (mA_cmd_start),
        .cmd_write (mA_cmd_write),
        .cmd_read  (mA_cmd_read),
        .cmd_stop  (mA_cmd_stop),

        .tx_data   (mA_tx_data),
        .rx_data   (mA_rx_data),
        .ack_in    (mA_ack_in),
        .ack_out   (mA_ack_out),

        .busy      (mA_busy),
        .done      (mA_done),

        .sda       (sda_bus),
        .scl       (scl_bus)
    );

    // Master B
    i2c_master u2_i2c_master (
        .clk       (clk),
        .reset     (reset),

        .cmd_start (mB_cmd_start),
        .cmd_write (mB_cmd_write),
        .cmd_read  (mB_cmd_read),
        .cmd_stop  (mB_cmd_stop),

        .tx_data   (mB_tx_data),
        .rx_data   (mB_rx_data),
        .ack_in    (mB_ack_in),
        .ack_out   (mB_ack_out),

        .busy      (mB_busy),
        .done      (mB_done),

        .sda       (sda_bus),
        .scl       (scl_bus)
    );

    task automatic masterA_start();
        begin
            mA_cmd_start = 1'b1;
            @(posedge clk);
            mA_cmd_start = 1'b0;
        end
    endtask

    task automatic masterB_start();
        begin
            mB_cmd_start = 1'b1;
            @(posedge clk);
            mB_cmd_start = 1'b0;
        end
    endtask

    task automatic masterA_write_byte(input logic [7:0] data);
        int timeout;
        begin
            timeout = 0;

            mA_tx_data   = data;
            mA_cmd_write = 1'b1;
            @(posedge clk);
            mA_cmd_write = 1'b0;

            while (!mA_done && timeout < 200000) begin
                @(posedge clk);
                timeout++;
            end

            if (timeout >= 200000)
                $display("[%0t] Master A timeout - probably arbitration lost", $time);
            else
                $display("[%0t] Master A write done", $time);

            @(posedge clk);
        end
    endtask

    task automatic masterB_write_byte(input logic [7:0] data);
        int timeout;
        begin
            timeout = 0;

            mB_tx_data   = data;
            mB_cmd_write = 1'b1;
            @(posedge clk);
            mB_cmd_write = 1'b0;

            while (!mB_done && timeout < 200000) begin
                @(posedge clk);
                timeout++;
            end

            if (timeout >= 200000)
                $display("[%0t] Master B timeout", $time);
            else
                $display("[%0t] Master B write done", $time);

            @(posedge clk);
        end
    endtask

    initial begin
        wait(reset == 1'b0);
        repeat (10) @(posedge clk);

        // 동시에 START
        fork
            masterA_start();
            masterB_start();
        join

        wait(mA_done && mB_done);
        @(posedge clk);

        // Arbitration Test
        // Master A : 1011_0000
        // Master B : 1001_0000
        // 세 번째 bit에서 A는 1 release, B는 0 drive
        // 따라서 SDA bus = 0, Master A arbitration lost
        fork
            masterA_write_byte(8'b1011_0000);
            masterB_write_byte(8'b1001_0000);
        join

        repeat (100) @(posedge clk);

        $stop;
    end

endmodule