`timescale 1ns / 1ps

// line collector로 부터
// line_data, line_length, line_valid가 들어온다.

// line_data를 분석한다.

// cmd type
// cmd_data
// cmd_valid

// 모두 완료가 된 후 parser_ready 를 line에 전송해준다.

module command_parser #(
    parameter LINE_MAX = 64
) (
    input  wire                          clk,
    input  wire                          rst_n,

    input  wire [        8*LINE_MAX-1:0] line_data,
    input  wire [$clog2(LINE_MAX+1)-1:0] line_length,
    input  wire                          line_valid,

    output reg  [15:0]                   cmd_data_1,   // hour
    output reg  [15:0]                   cmd_data_2,   // min
    output reg  [15:0]                   cmd_data_3,   // sec
    output reg  [15:0]                   cmd_data_4,   // msec

    output reg  [3:0]                    cmd_type,   // 0~15
    output reg                           cmd_valid,
    output reg                           cmd_error
);

    // command type
    localparam CMD_NOP = 4'd0;
    localparam CMD_STOPWATCH_RUN = 4'd1;
    localparam CMD_STOPWATCH_CLEAR = 4'd2;
    localparam CMD_STOPWATCH_MODE = 4'd3;

    // 미구현
    localparam CMD_TIME_SEL = 4'd4;
    localparam CMD_WATCH_SET = 4'd5;
    localparam CMD_WATCH_TIME = 4'd6; // watch 시간

    localparam CMD_ULTRASONIC = 4'd7;
    localparam CMD_TEMP = 4'd8;

    // line_data를 8bit ASCII 문자 배열로 분리
    wire [7:0] c [0:LINE_MAX-1];

    genvar i;
    generate
        for (i = 0; i < LINE_MAX; i = i + 1) begin : GEN_CHAR
            assign c[i] = line_data[8*i +: 8];
        end
    endgenerate

    // ASCII 숫자 문자 -> 4bit 숫자 변환
    // 숫자가 아니면 4'hF 반환
    function [3:0] ascii_to_digit;
        input [7:0] ch;
        begin
            if (ch >= "0" && ch <= "9")
                ascii_to_digit = ch - "0";
            else
                ascii_to_digit = 4'hF;
        end
    endfunction

    wire [3:0] d [0:LINE_MAX-1];

    generate
        for (i = 0; i < LINE_MAX; i = i + 1) begin : GEN_CHAR_TO_DIGIT
            assign d[i] = ascii_to_digit(c[i]);
        end
    endgenerate

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cmd_data_1  <= 16'd0;
            cmd_data_2  <= 16'd0;
            cmd_data_3  <= 16'd0;
            cmd_data_4  <= 16'd0;
            cmd_type  <= CMD_NOP;
            cmd_valid <= 1'b0;
            cmd_error <= 1'b0;
        end else begin
            // pulse 신호
            cmd_valid <= 1'b0;
            cmd_error <= 1'b0;

            if (line_valid) begin

                // stopwatch run/stop
                if (line_length == 18 &&
                    c[0] == "S" && c[1] == "T" && c[2] == "O" && c[3] == "P"  && c[4] == "W" &&
                    c[5] == "A" && c[6] == "T" && c[7] == "C" && c[8] == "H" && c[9] == " " &&
                    c[10] == "R" && c[11] == "U" && c[12] == "N" && c[13] == "/" && c[14] == "S" &&
                    c[15] == "T" && c[16] == "O" && c[17] == "P"
                    ) begin

                    cmd_type  <= CMD_STOPWATCH_RUN;
                    cmd_data_1  <= 16'd0;
                    cmd_data_2  <= 16'd0;
                    cmd_data_3  <= 16'd0;
                    cmd_data_4  <= 16'd0;
                    cmd_valid <= 1'b1;
                end

                // stopwatch clear
                else if (line_length == 15 &&
                    c[0] == "S" && c[1] == "T" && c[2] == "O" && c[3] == "P"  && c[4] == "W" &&
                    c[5] == "A" && c[6] == "T" && c[7] == "C" && c[8] == "H" && c[9] == " " &&
                    c[10] == "C" && c[11] == "L" && c[12] == "E" && c[13] == "A" && c[14] == "R"
                    ) begin

                    cmd_type  <= CMD_STOPWATCH_CLEAR;
                    cmd_data_1  <= 16'd0;
                    cmd_data_2  <= 16'd0;
                    cmd_data_3  <= 16'd0;
                    cmd_data_4  <= 16'd0;
                    cmd_valid <= 1'b1;
                end

                // stopwatch mode
                else if (line_length == 14 &&
                    c[0] == "S" && c[1] == "T" && c[2] == "O" && c[3] == "P"  && c[4] == "W" &&
                    c[5] == "A" && c[6] == "T" && c[7] == "C" && c[8] == "H" && c[9] == " " &&
                    c[10] == "M" && c[11] == "O" && c[12] == "D" && c[13] == "E"
                    ) begin

                    cmd_type  <= CMD_STOPWATCH_MODE;
                    cmd_data_1  <= 16'd0;
                    cmd_data_2  <= 16'd0;
                    cmd_data_3  <= 16'd0;
                    cmd_data_4  <= 16'd0;
                    cmd_valid <= 1'b1;
                end

/*
                // TIME SEL HOUR
                else if (line_length == 13 &&
                    c[0] == "T" && c[1] == "I" && c[2] == "M" && c[3] == "E"  && c[4] == " " &&
                    c[5] == "S" && c[6] == "E" && c[7] == "L" && c[8] == " " && c[9] == "H" &&
                    c[10] == "O" && c[11] == "U" && c[12] == "R"
                    ) begin

                    cmd_type  <= CMD_TIME_SEL;
                    cmd_data  <= 16'd0;
                    cmd_valid <= 1'b1;
                end
*/
                // WATCH 12:00:00:00
                else if (line_length == 17 &&
                    c[0] == "W" && c[1] == "A" && c[2] == "T" && c[3] == "C"  && c[4] == "H" &&
                    c[5] == " " && d[6] != 4'hF && d[7] != 4'hF && c[8] == ":" && d[9] != 4'hF &&
                    d[10] != 4'hF && c[11] == ":" && d[12] != 4'hF && d[13] != 4'hF && c[14] == ":" &&
                    d[15] != 4'hF && d[16] != 4'hF 
                    ) begin

                    cmd_type  <= CMD_WATCH_SET;
                    cmd_data_1  <= d[6] * 16'd10 + d[7];
                    cmd_data_2  <= d[9] * 16'd10 + d[10];
                    cmd_data_3  <= d[12] * 16'd10 + d[13];
                    cmd_data_4  <= d[15] * 16'd10 + d[16];
                    cmd_valid <= 1'b1;
                end

                // Unknown command
                else begin
                    cmd_type  <= CMD_NOP;
                    cmd_data_1  <= 16'd0;
                    cmd_data_2  <= 16'd0;
                    cmd_data_3  <= 16'd0;
                    cmd_data_4  <= 16'd0;
                    cmd_valid <= 1'b1;
                    cmd_error <= 1'b1;
                end
            end
        end
    end

endmodule
