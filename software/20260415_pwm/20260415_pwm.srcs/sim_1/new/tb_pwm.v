`timescale 1ns / 1ps

module tb_pwm;
    reg  clk;
    reg [18:0] period;
    reg [18:0] duty;
    reg  rst_n;
    wire pwm;

    pwm #(
        .CLOCK_FREQ_HZ(100_000_000),
        .CNT_WIDTH(19)
    ) u_pwm (
        .clk(clk),
        .rst_n(rst_n),
        .period(period),  // 100_000_000 / 1000Hz = 100_000
        .duty(duty),  // 0~100% need change
        .pwm(pwm)
    );

    initial begin
        clk   = 0;
        rst_n = 0;
        #10;
        rst_n = 1;

        @(negedge clk);
        // 100_000_000 / 1000hz = 100_000
        period = 100_000;
        duty = 10_000; // 10%
        #100_000_000;

        duty = 50_000;
    
        #100_000_000;

        $finish;
    end

    always #5 clk = ~clk;
endmodule
