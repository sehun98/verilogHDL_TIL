`timescale 1ns / 1ps

module control_unit_watch (
    input wire clk,
    input wire rst_n,

    input wire btn_right,
    input wire btn_left,
    input wire btn_down,
    input wire btn_up,

    input wire set_mode,

    output reg  [2:0] digit_sel,
    output wire       up,
    output wire       down
);

    assign up   = set_mode & btn_up;
    assign down = set_mode & btn_down;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n || !set_mode) begin // setmode가 켜지지 않으면 digit_sel 을 초기화
            digit_sel <= 3'd0;
        end else begin
            if (set_mode) begin
                if (btn_right) begin
                    digit_sel <= (digit_sel == 3'd7) ? 3'd0 : digit_sel + 3'd1;
                end else if (btn_left) begin
                    digit_sel <= (digit_sel == 3'd0) ? 3'd7 : digit_sel - 3'd1;
                end
            end
        end
    end

endmodule
