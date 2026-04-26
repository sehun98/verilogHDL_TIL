`timescale 1ns / 1ps

module command_executor (
    input wire clk,
    input wire rst_n,

    input wire [15:0] cmd_data,
    input wire [ 3:0] cmd_type,
    input wire        cmd_valid,

    output reg [ 3:0] led,
    output reg [15:0] fnd_value,

    input wire fifo_full,
    output reg fifo_w_en,
    output reg [7:0] fifo_data,

    output reg status_req,
    output reg reset_req,
    output reg exec_done
);

    localparam CMD_NOP     = 4'd0;
    localparam CMD_LED_ON  = 4'd1;
    localparam CMD_LED_OFF = 4'd2;
    localparam CMD_FND_SET = 4'd3;
    localparam CMD_STATUS  = 4'd4;
    localparam CMD_RESET   = 4'd5;

    reg error_send;
    reg [2:0] cnt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            led        <= 4'b0000;
            fnd_value  <= 16'd0;
            status_req <= 1'b0;
            reset_req  <= 1'b0;
            exec_done  <= 1'b0;

            fifo_w_en  <= 1'b0;
            fifo_data  <= 8'd0;
            error_send <= 1'b0;
            cnt        <= 3'd0;
        end else begin
            status_req <= 1'b0;
            reset_req  <= 1'b0;
            exec_done  <= 1'b0;
            fifo_w_en  <= 1'b0;

            if (cmd_valid) begin
                exec_done <= 1'b1;

                case (cmd_type)

                    CMD_NOP: begin
                        error_send <= 1'b1;
                        cnt        <= 3'd0;
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
                        error_send <= 1'b1;
                        cnt        <= 3'd0;
                    end

                endcase
            end

            if (error_send) begin
                if (!fifo_full) begin
                    fifo_w_en <= 1'b1;

                    case (cnt)
                        3'd0: fifo_data <= "E";
                        3'd1: fifo_data <= "R";
                        3'd2: fifo_data <= "R";
                        3'd3: fifo_data <= "O";
                        3'd4: fifo_data <= "R";
                        3'd5: fifo_data <= 8'h0D;
                        3'd6: fifo_data <= 8'h0A;
                        default: fifo_data <= 8'h00;
                    endcase

                    if (cnt == 3'd6) begin
                        error_send <= 1'b0;
                        cnt        <= 3'd0;
                    end else begin
                        cnt <= cnt + 1'b1;
                    end
                end
            end
        end
    end

endmodule