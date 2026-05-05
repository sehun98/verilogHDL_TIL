`timescale 1ns / 1ps

module tb_top_system_dht11;

    reg clk;
    reg rst_n;

    reg rx;
    wire tx;

    wire [3:0] digit;
    wire [7:0] seg;
    wire [1:0] led;

    reg btnR;
    reg btnL;
    reg btnU;
    reg btnD;

    reg setmode_sw;
    reg stopwatch_watch_sw;
    reg hourmin_secmsec_sw;
    reg ultra_temp_sel_sw;
    reg watch_sensor_sw;

    wire dht11;
    wire trig;
    reg echo;

    reg dht11_drive_en;
    reg dht11_drive_data;

    assign dht11 = dht11_drive_en ? dht11_drive_data : 1'bz;
    pullup(dht11);

    localparam BAUD_RATE = 115200;
    localparam BIT_TIME  = 1_000_000_000 / BAUD_RATE;

    reg [39:0] dht11_packet;
    integer i;

    top_system u1_top_system (
        .clk(clk),
        .rst_n(rst_n),

        .digit(digit),
        .seg(seg),
        .led(led),

        .btnR(btnR),
        .btnL(btnL),
        .btnU(btnU),
        .btnD(btnD),

        .setmode_sw(setmode_sw),
        .stopwatch_watch_sw(stopwatch_watch_sw),
        .hourmin_secmsec_sw(hourmin_secmsec_sw),
        .ultra_temp_sel_sw(ultra_temp_sel_sw),
        .watch_sensor_sw(watch_sensor_sw),

        .dht11(dht11),
        .trig(trig),
        .echo(echo),

        .rx(rx),
        .tx(tx)
    );

    always #5 clk = ~clk;

    task uart_send_byte;
        input [7:0] data;
        integer j;
        begin
            rx = 1'b1;
            #(BIT_TIME);

            rx = 1'b0;
            #(BIT_TIME);

            for (j = 0; j < 8; j = j + 1) begin
                rx = data[j];
                #(BIT_TIME);
            end

            rx = 1'b1;
            #(BIT_TIME);
        end
    endtask

    task send_dht11_command;
        begin
            uart_send_byte("D");
            uart_send_byte("H");
            uart_send_byte("T");
            uart_send_byte("1");
            uart_send_byte("1");
            uart_send_byte(8'h0A);
        end
    endtask

    task dht11_send_bit;
        input bit_value;
        begin
            // DATA_SYNC 상태에서 Low 구간 감지
            dht11_drive_en   = 1'b1;
            dht11_drive_data = 1'b0;
            #(50_000);

            // DATA_COUNT 상태에서 High 폭 측정
            dht11_drive_data = 1'b1;

            if (bit_value == 1'b0)
                #(28_000);
            else
                #(70_000);

            // 다음 bit 준비
            dht11_drive_data = 1'b0;
            #(5_000);
        end
    endtask

    task dht11_response;
        begin
            // FPGA START Low 감지
            wait (dht11 === 1'b0);

            // FPGA가 WAIT에서 High로 올리는 구간 감지
            wait (dht11 === 1'b1);

            // controller의 SYNCL 상태 대응:
            // 라인이 High 상태로 40us 이상 유지되어야 함
            dht11_drive_en = 1'b0;
            #(60_000);

            // controller의 SYNCH 상태 대응:
            // 라인이 Low 상태로 40us 이상 유지되어야 함
            dht11_drive_en   = 1'b1;
            dht11_drive_data = 1'b0;
            #(80_000);

            // DATA_SYNC 진입용 High
            dht11_drive_data = 1'b1;
            #(80_000);

            // 40bit 데이터 전송, MSB first
            for (i = 39; i >= 0; i = i - 1) begin
                dht11_send_bit(dht11_packet[i]);
            end

            dht11_drive_en   = 1'b0;
            dht11_drive_data = 1'b1;
        end
    endtask

    initial begin
        clk = 0;
        rst_n = 0;

        rx = 1'b1;
        echo = 1'b0;

        btnR = 0;
        btnL = 0;
        btnU = 0;
        btnD = 0;

        setmode_sw = 0;
        stopwatch_watch_sw = 0;
        hourmin_secmsec_sw = 0;
        ultra_temp_sel_sw = 0;
        watch_sensor_sw = 0;

        dht11_drive_en   = 1'b0;
        dht11_drive_data = 1'b1;

        // humidity = 55, temperature = 24, checksum = 79
        dht11_packet = {8'd55, 8'd0, 8'd24, 8'd0, 8'd79};

        #100;
        rst_n = 1;

        #(BIT_TIME * 5);

        $display("[%0t] Send command: DHT11", $time);

        fork
            send_dht11_command();
            dht11_response();
        join

        #(20_000_000);

        $display("[%0t] DHT11 test finished", $time);
        $finish;
    end

endmodule