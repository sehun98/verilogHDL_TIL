`timescale 1ns / 1ps

module command_executor (
    input  wire        clk,
    input  wire        rst_n,

    input  wire [15:0] cmd_data,
    input  wire [3:0]  cmd_type,
    input  wire        cmd_valid,

    output reg  [3:0]  led,
    output reg  [15:0] fnd_value,

    output reg         status_req,
    output reg         reset_req,
    output reg         exec_done
);

    localparam CMD_NOP     = 4'd0;
    localparam CMD_LED_ON  = 4'd1;
    localparam CMD_LED_OFF = 4'd2;
    localparam CMD_FND_SET = 4'd3;
    localparam CMD_STATUS  = 4'd4;
    localparam CMD_RESET   = 4'd5;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            led        <= 4'b0000;
            fnd_value  <= 16'd0;
            status_req <= 1'b0;
            reset_req  <= 1'b0;
            exec_done  <= 1'b0;
        end else begin
            status_req <= 1'b0;
            reset_req  <= 1'b0;
            exec_done  <= 1'b0;

            if (cmd_valid) begin
                exec_done <= 1'b1;

                case (cmd_type)

                    CMD_NOP: begin
                        // 동작 없음
                    end

                    CMD_LED_ON: begin
                        led <= led | cmd_data[3:0];
                    end

                    CMD_LED_OFF: begin
                        led <= led & ~cmd_data[3:0];
                    end

                    CMD_FND_SET: begin
                        fnd_value <= cmd_data;
                    end

                    CMD_STATUS: begin
                        status_req <= 1'b1;
                    end

                    CMD_RESET: begin
                        reset_req <= 1'b1;
                    end

                    default: begin
                        // parser에서 이미 걸러졌다고 가정
                    end

                endcase
            end
        end
    end

endmodule