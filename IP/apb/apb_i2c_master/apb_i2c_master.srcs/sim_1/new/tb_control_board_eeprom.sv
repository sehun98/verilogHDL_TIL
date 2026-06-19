`timescale 1ns / 1ps

module tb_control_board_eeprom;
    logic       clk;
    logic       rst_n;
    logic [2:0] chip_select;
    logic       btn_write;
    logic       btn_read;
    logic [3:0] digit;
    logic [7:0] seg;
    logic       scl;
    wire        sda;
    logic [7:0] saved_data;

    pullup(sda);

    initial clk = 1'b0;
    always #5 clk = ~clk;

    control_board #(
        .CLK_FREQ_HZ(100_000),
        .DEBOUNCE_MS(1)
    ) dut (
        .clk        (clk),
        .rst_n      (rst_n),
        .digit      (digit),
        .seg        (seg),
        .chip_select(chip_select),
        .btn_write  (btn_write),
        .btn_read   (btn_read),
        .scl        (scl),
        .sda        (sda)
    );

    eeprom u_eeprom (
        .clk        (clk),
        .rst_n      (rst_n),
        .chip_select(chip_select),
        .scl        (scl),
        .sda        (sda)
    );

    task automatic press_button(ref logic button);
        begin
            button = 1'b1;
            repeat (120) @(posedge clk);
            button = 1'b0;
            repeat (120) @(posedge clk);
        end
    endtask

    task automatic wait_control_idle;
        integer timeout;
        begin
            timeout = 0;
            while ((dut.u5_control_unit.state != 2'b00) && (timeout < 300_000)) begin
                @(posedge clk);
                timeout = timeout + 1;
            end
            if (timeout == 300_000)
                $fatal(1, "Timeout waiting for control_unit IDLE");
        end
    endtask

    initial begin
        #20_000_000;
        $fatal(1, "Timeout: control_board EEPROM integration test did not finish");
    end

    initial begin
        rst_n       = 1'b0;
        chip_select = 3'b000;
        btn_write   = 1'b0;
        btn_read    = 1'b0;

        repeat (10) @(posedge clk);
        rst_n = 1'b1;
        repeat (10) @(posedge clk);

        wait (dut.w_count >= 14'd5);
        if (dut.w_data !== dut.w_count)
            $fatal(1, "Display data did not follow count: count=%0d, display_data=%0d",
                   dut.w_count, dut.w_data);

        press_button(btn_write);
        wait (dut.u5_control_unit.state != 2'b00);
        wait_control_idle();

        saved_data = u_eeprom.u2_eeprom_data_path.eeprom[8'h10];
        if (saved_data !== dut.u5_control_unit.tx_data)
            $fatal(1, "EEPROM write mismatch: tx_data=%02h, EEPROM=%02h",
                   dut.u5_control_unit.tx_data, saved_data);

        wait (dut.w_count >= 14'd10);

        press_button(btn_read);
        wait (dut.u5_control_unit.state != 2'b00);
        wait_control_idle();

        if (dut.w_count !== {6'd0, saved_data})
            $fatal(1, "Count update mismatch: expected %0d, got %0d",
                   saved_data, dut.w_count);

        if (dut.w_data !== {6'd0, saved_data})
            $fatal(1, "Display data mismatch: expected %0d, got %0d",
                   saved_data, dut.w_data);

        $display("TEST PASS: EEPROM[10]=%02h, count=%0d, display_data=%0d",
                 u_eeprom.u2_eeprom_data_path.eeprom[8'h10],
                 dut.w_count, dut.w_data);
        $finish;
    end
endmodule
