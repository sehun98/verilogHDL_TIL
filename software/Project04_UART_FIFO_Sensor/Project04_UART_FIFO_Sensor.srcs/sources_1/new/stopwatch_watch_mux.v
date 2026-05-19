`timescale 1ns / 1ps

module stopwatch_watch_mux (
    input wire [6:0] stopwatch_msec,
    input wire [5:0] stopwatch_sec,
    input wire [5:0] stopwatch_min,
    input wire [4:0] stopwatch_hour,
    input wire [6:0] watch_msec,
    input wire [5:0] watch_sec,
    input wire [5:0] watch_min,
    input wire [4:0] watch_hour,
    input wire sel, // High : stopwatch, Low : watch

    output wire [6:0] msec,
    output wire [5:0] sec,
    output wire [5:0] min,
    output wire [4:0] hour
);
    assign msec = sel ? stopwatch_msec : watch_msec;
    assign sec = sel ? stopwatch_sec : watch_sec;
    assign min = sel ? stopwatch_min : watch_min;
    assign hour = sel ? stopwatch_hour : watch_hour;

endmodule
