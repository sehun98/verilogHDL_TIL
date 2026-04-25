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

    output reg  [15:0]                   cmd_data,   // 0~65535
    output reg  [3:0]                    cmd_type,   // 0~15
    output reg                           cmd_valid,
    output reg                           cmd_error
);

    // command type
    localparam CMD_NOP     = 4'd0;
    localparam CMD_LED_ON  = 4'd1;
    localparam CMD_LED_OFF = 4'd2;
    localparam CMD_FND_SET = 4'd3;
    localparam CMD_STATUS  = 4'd4;
    localparam CMD_RESET   = 4'd5;

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
            cmd_data  <= 16'd0;
            cmd_type  <= CMD_NOP;
            cmd_valid <= 1'b0;
            cmd_error <= 1'b0;
        end else begin
            // pulse 신호
            cmd_valid <= 1'b0;
            cmd_error <= 1'b0;

            if (line_valid) begin

                // LED ON
                if (line_length == 6 &&
                    c[0] == "L" && c[1] == "E" && c[2] == "D" &&
                    c[3] == " " &&
                    c[4] == "O" && c[5] == "N") begin

                    cmd_type  <= CMD_LED_ON;
                    cmd_data  <= 16'h000F;   // LED 전체 ON
                    cmd_valid <= 1'b1;
                end

                // LED OFF
                else if (line_length == 7 &&
                    c[0] == "L" && c[1] == "E" && c[2] == "D" &&
                    c[3] == " " &&
                    c[4] == "O" && c[5] == "F" && c[6] == "F") begin

                    cmd_type  <= CMD_LED_OFF;
                    cmd_data  <= 16'h000F;   // LED 전체 OFF
                    cmd_valid <= 1'b1;
                end

                // FND 1234
                else if (line_length == 8 &&
                    c[0] == "F" && c[1] == "N" && c[2] == "D" &&
                    c[3] == " " &&
                    d[4] != 4'hF && d[5] != 4'hF &&
                    d[6] != 4'hF && d[7] != 4'hF) begin

                    cmd_type  <= CMD_FND_SET;
                    cmd_data  <= (d[4] * 16'd1000) +
                                 (d[5] * 16'd100)  +
                                 (d[6] * 16'd10)   +
                                  d[7];
                    cmd_valid <= 1'b1;
                end

                // STATUS
                else if (line_length == 6 &&
                    c[0] == "S" && c[1] == "T" && c[2] == "A" &&
                    c[3] == "T" && c[4] == "U" && c[5] == "S") begin

                    cmd_type  <= CMD_STATUS;
                    cmd_data  <= 16'd0;
                    cmd_valid <= 1'b1;
                end

                // RESET
                else if (line_length == 5 &&
                    c[0] == "R" && c[1] == "E" && c[2] == "S" &&
                    c[3] == "E" && c[4] == "T") begin

                    cmd_type  <= CMD_RESET;
                    cmd_data  <= 16'd0;
                    cmd_valid <= 1'b1;
                end

                // Unknown command
                else begin
                    cmd_type  <= CMD_NOP;
                    cmd_data  <= 16'd0;
                    cmd_error <= 1'b1;
                end
            end
        end
    end

endmodule

/*

line_collector #(
    parameter LINE_MAX = 64
) (
    input  wire                          clk,
    input  wire                          rst_n,

    output reg                           fifo_r_en, // en 신호를 인가하면 fifo로 부터 데이터가 들어온다.
    input  wire [                   7:0] fifo_data, // 읽오는 데이터
    input  wire                          fifo_empty, // high 일 때 비어 있으므로 데이터를 읽지 말아야 한다.

    output reg  [        8*LINE_MAX-1:0] line_data, // 문장이 완성된 데이터를 전송해준다.
    output reg  [$clog2(LINE_MAX+1)-1:0] line_length, // 문장의 길이를 전송해준다.
    output reg                           line_valid, // 문장이 완성되지 않았을 때 valid를 0으로 유지 시킨다, 문장이 전송이 되어도 0이 된다.

    input  wire                          ready // 상대방에게 문장을 보낼 수 있다는 신호가 들어온다.
);

*/
