`timescale 1ns / 1ps

module watch_datapath (
    input wire clk,
    input wire rst_n,

    input wire set_mode,

    input wire up,
    input wire down,

    input wire [2:0] digit_sel,

    output wire [6:0] msec,
    output wire [5:0] sec,
    output wire [5:0] min,
    output wire [4:0] hour
);

    wire       w_tick_100hz;
    wire       w_sec;
    wire       w_min;
    wire       w_hour;

    reg        set_en_msec;
    reg        set_en_sec;
    reg        set_en_min;
    reg        set_en_hour;

    reg  [6:0] set_value_msec;
    reg  [5:0] set_value_sec;
    reg  [5:0] set_value_min;
    reg  [4:0] set_value_hour;

    tick_gen_100hz #(
        .CLOCK_FREQ_HZ(100_000_000),
        .COUNT_HZ     (100)
    ) u1_tick_gen_100hz (
        .clk       (clk),
        .rst_n     (rst_n),
        .tick_100hz(w_tick_100hz)
    );

    n_modulo_counter_watch #(
        .N(100),
        .TIME_SET(0)
    ) u2_msec (
        .clk       (clk),
        .rst_n     (rst_n),
        .en        (w_tick_100hz & ~set_mode),
        .set_en    (set_en_msec),
        .set_value (set_value_msec),
        .count     (msec),
        .tick      (w_sec)
    );

    n_modulo_counter_watch #(
        .N(60),
        .TIME_SET(0)
    ) u3_sec (
        .clk       (clk),
        .rst_n     (rst_n),
        .en        (w_sec),
        .set_en    (set_en_sec),
        .set_value (set_value_sec),
        .count     (sec),
        .tick      (w_min)
    );

    n_modulo_counter_watch #(
        .N(60),
        .TIME_SET(0)
    ) u4_min (
        .clk       (clk),
        .rst_n     (rst_n),
        .en        (w_min),
        .set_en    (set_en_min),
        .set_value (set_value_min),
        .count     (min),
        .tick      (w_hour)
    );

    n_modulo_counter_watch #(
        .N(24),
        .TIME_SET(12)
    ) u5_hour (
        .clk       (clk),
        .rst_n     (rst_n),
        .en        (w_hour),
        .set_en    (set_en_hour),
        .set_value (set_value_hour),
        .count     (hour),
        .tick      ()
    );

    always @(*) begin
        // 기본값
        set_en_msec     = 1'b0;
        set_en_sec      = 1'b0;
        set_en_min      = 1'b0;
        set_en_hour     = 1'b0;

        set_value_msec  = msec;
        set_value_sec   = sec;
        set_value_min   = min;
        set_value_hour  = hour;

        if (up) begin
            case (digit_sel)
                3'd0: begin
                    set_en_hour = 1'b1;
                    if (hour >= 20) set_value_hour = hour - 20;
                    else if (hour >= 14) set_value_hour = hour - 10;
                    else set_value_hour = hour + 10;
                end

                3'd1: begin
                    set_en_hour = 1'b1;
                    if (hour == 23) set_value_hour = 0;
                    else set_value_hour = hour + 1;
                end

                3'd2: begin
                    set_en_min = 1'b1;
                    if (min >= 50) set_value_min = min - 50;
                    else set_value_min = min + 10;
                end

                3'd3: begin
                    set_en_min = 1'b1;
                    if (min == 59) set_value_min = 0;
                    else set_value_min = min + 1;
                end

                3'd4: begin
                    set_en_sec = 1'b1;
                    if (sec >= 50) set_value_sec = sec - 50;
                    else set_value_sec = sec + 10;
                end

                3'd5: begin
                    set_en_sec = 1'b1;
                    if (sec == 59) set_value_sec = 0;
                    else set_value_sec = sec + 1;
                end

                3'd6: begin
                    set_en_msec = 1'b1;
                    if (msec >= 90) set_value_msec = msec - 90;
                    else set_value_msec = msec + 10;
                end

                3'd7: begin
                    set_en_msec = 1'b1;
                    if (msec == 99) set_value_msec = 0;
                    else set_value_msec = msec + 1;
                end
            endcase
        end
        else if (down) begin
            case (digit_sel)
                3'd0: begin
                    set_en_hour = 1'b1;
                    if (hour < 4) set_value_hour = hour + 20;
                    else if (hour < 10) set_value_hour = hour + 10;
                    else set_value_hour = hour - 10;
                end

                3'd1: begin
                    set_en_hour = 1'b1;
                    if (hour == 0) set_value_hour = 23;
                    else set_value_hour = hour - 1;
                end

                3'd2: begin
                    set_en_min = 1'b1;
                    if (min < 10) set_value_min = min + 50;
                    else set_value_min = min - 10;
                end

                3'd3: begin
                    set_en_min = 1'b1;
                    if (min == 0) set_value_min = 59;
                    else set_value_min = min - 1;
                end

                3'd4: begin
                    set_en_sec = 1'b1;
                    if (sec < 10) set_value_sec = sec + 50;
                    else set_value_sec = sec - 10;
                end

                3'd5: begin
                    set_en_sec = 1'b1;
                    if (sec == 0) set_value_sec = 59;
                    else set_value_sec = sec - 1;
                end

                3'd6: begin
                    set_en_msec = 1'b1;
                    if (msec < 10) set_value_msec = msec + 90;
                    else set_value_msec = msec - 10;
                end

                3'd7: begin
                    set_en_msec = 1'b1;
                    if (msec == 0) set_value_msec = 99;
                    else set_value_msec = msec - 1;
                end
            endcase
        end
    end

endmodule