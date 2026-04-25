`timescale 1ns / 1ps

module tb_spi_adc081s02;
    reg clk;
    reg rst_n;
    wire w_sclk_square;
    reg request;
    wire [11:0] voltage_mv;
    wire adc_busy;
    wire CS;
    reg MISO;
    wire SCLK;

    wire [7:0] w_adc_data;

    sclk_gen #(
        .CLOCK_FREQ_HZ(100_000_000),
        .DIV_HALF(32)
    ) u2_sclk_gen (
        .clk(clk),
        .rst_n(rst_n),
        .sclk_square(w_sclk_square)
    );

    spi_adc081s02 u1_spi_adc081s02 (
        .clk(clk),
        .rst_n(rst_n),
        .sclk_square(w_sclk_square),
        .request(request),
        .adc_data(w_adc_data),
        .adc_busy(adc_busy),
        .CS(CS),
        .MISO(MISO),
        .SCLK(SCLK)
    );

    adc_to_voltage w_adc_to_voltage (
        .adc_data(w_adc_data),
        .voltage_mv(voltage_mv)
    );

    localparam DELAY = 100_000;
    integer i;

    task request_task;
        begin
            @(negedge clk);
            request = 1;
            @(negedge clk);
            request = 0;
        end
    endtask

    task MISO_task;
        input [7:0] t_data;
        begin
            @(negedge CS);
            repeat(3) begin 
                MISO = 0;
                @(negedge SCLK);
            end
            for (i = 0; i < 8; i = i + 1) begin
                @(negedge SCLK);
                MISO = t_data[7-i];
            end
            repeat(5) begin 
                @(negedge SCLK);
                MISO = 0;
            end
            MISO = 1'bx;
        end
    endtask

    always #5 clk = ~clk;
    initial begin
        clk = 0;
        rst_n = 0;
        request = 0;
        MISO = 1'bx;
        repeat (5) @(negedge clk);
        rst_n = 1;

        #(DELAY);

        fork
            request_task();
            MISO_task(8'h30);
        join

        #(DELAY);
        $display("adc_data = %h", voltage_mv);
        $finish;
    end


endmodule
