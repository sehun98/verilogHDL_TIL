`timescale 1ns / 1ps

// HY-SRF05 Precision Ultrasonic sensor
// start : 1us tigger pulse
// The sensor will automatically send out a 40kHz wave
// tirgger : active high
// echo : active high

// 2cm ~ 450cm
// elapsed time * 0.034 / 2
module tb_ultrasonic;
    reg clk;
    reg rst_n;
    reg start;
    wire [9:0] distance;
    wire trig;
    reg echo;

    ultrasonic u1_ultrasonic (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .distance(distance),
        .trig(trig),
        .echo(echo)
    );

    always #5 clk = ~clk;

    // echo pulse task
    // delay_us      : trig 이후 echo가 올라오기 전까지의 시간
    // high_time_us  : echo가 high로 유지되는 시간
    task send_echo_pulse;
        input integer delay_us;
        input integer high_time_us;
        begin
            #(delay_us * 1000);  // us -> ns
            echo = 1'b1;
            #(high_time_us * 1000);
            echo = 1'b0;
        end
    endtask

    initial begin
        {clk, rst_n, start, echo} = 4'b0000;

        // reset
        #100;
        rst_n = 1'b1;

        // -------------------------------
        // Case 1 : about 10cm
        // time = distance * 2 / 0.034
        //      = 10 * 2 / 0.034 = about 588us
        // -------------------------------
        #100;
        start = 1'b1;
        #10;
        start = 1'b0;

        wait (trig == 1'b1);
        wait (trig == 1'b0);

        send_echo_pulse(100, 588);

        #100000;

        // -------------------------------
        // Case 2 : about 20cm
        // time = 20 * 2 / 0.034 = about 1176us
        // -------------------------------
        start = 1'b1;
        #10;
        start = 1'b0;

        wait (trig == 1'b1);
        wait (trig == 1'b0);

        send_echo_pulse(100, 1176);

        #150000;


        // -------------------------------
        // Case 3 : about 450cm
        // time = 450 * 2 / 0.034 = about 26470us
        // -------------------------------
        start = 1'b1;
        #10;
        start = 1'b0;

        wait (trig == 1'b1);
        wait (trig == 1'b0);

        send_echo_pulse(100, 26470);

        #200000;


        // -------------------------------
        // Case 4 : timeout test
        // echo does not come
        // -------------------------------
        start = 1'b1;
        #10;
        start = 1'b0;

        #40000000;

        $finish;
    end

    initial begin
        $monitor("time=%0t ns, start=%b, trig=%b, echo=%b, distance=%d", $time,
                 start, trig, echo, distance);
    end

endmodule
