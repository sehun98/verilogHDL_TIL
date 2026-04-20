`timescale 1ns / 1ps

module uart_rx (
    input wire clk,
    input wire rst_n,
    input wire rx_baud_tick,

    output wire busy,
    output reg done,
    output reg [7:0] data,
    output reg frame_error,

    input wire rx
);

    localparam IDLE = 2'b00;
    localparam START = 2'b01;
    localparam SIPO = 2'b10;
    localparam STOP = 2'b11;

    // 0~3
    reg [1:0] state, n_state;
    // 0~16
    reg [3:0] oversample_count;
    // 0~7
    reg [2:0] data_count;

    reg [7:0] rx_shift_reg;

    reg sync_ff_1;
    reg sync_ff_2;

    // 1. 2 sync ff
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_ff_1 <= 1'b0;
            sync_ff_2 <= 1'b0;
        end else begin
            sync_ff_1 <= rx;
            sync_ff_2 <= sync_ff_1;
        end
    end

    // 2. state register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
        end else begin
            state <= n_state;
        end
    end

    // 3. next state logic
    always @(*) begin
        n_state = state;
        case (state)
            IDLE: if (!sync_ff_2) n_state = START;
            START:
            if (rx_baud_tick && oversample_count == 4'd7) begin
                if (!sync_ff_2) n_state = SIPO;
                else n_state = IDLE;
            end
            SIPO:
            if (rx_baud_tick && oversample_count == 4'd15 && data_count == 3'd7)
                n_state = STOP;
            STOP: begin
                if (rx_baud_tick && oversample_count == 4'd15) n_state = IDLE;
            end
            default: n_state = IDLE;
        endcase
    end

    // 4. oversample_count 
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            oversample_count <= 4'd0;
        end else begin
            if (rx_baud_tick) begin
                case (state)
                    IDLE: oversample_count <= 4'd0;
                    START:
                    if (oversample_count == 4'd7) begin
                        oversample_count <= 4'd0;
                    end else begin
                        oversample_count <= oversample_count + 4'd1;
                    end
                    SIPO:
                    if (oversample_count == 4'd15) begin
                        oversample_count <= 4'd0;
                    end else begin
                        oversample_count <= oversample_count + 4'd1;
                    end
                    STOP:
                    if (oversample_count == 4'd15) begin
                        oversample_count <= 4'd0;
                    end else begin
                        oversample_count <= oversample_count + 4'd1;
                    end
                    default: oversample_count <= 4'd0;
                endcase
            end
        end
    end

    // 5. data_count
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_count <= 3'd0;
        end else begin
            if (rx_baud_tick) begin
                case (state)
                    IDLE: data_count <= 3'd0;
                    START: data_count <= 3'd0;
                    SIPO:
                    if (oversample_count == 4'd15) begin
                        if (data_count == 3'd7) begin
                            data_count <= 3'd0;
                        end else begin
                            data_count <= data_count + 3'd1;
                        end
                    end
                    STOP: data_count <= 3'd0;
                    default: data_count <= 3'd0;
                endcase
            end
        end
    end

    // 6. data path
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_shift_reg <= 8'd0;
            data         <= 8'd0;
        end else begin
            if (rx_baud_tick) begin
                case (state)
                    IDLE: rx_shift_reg <= 8'd0;
                    START: rx_shift_reg <= 8'd0;
                    SIPO: begin
                        if (oversample_count == 4'd15) begin
                            rx_shift_reg[data_count] <= sync_ff_2;
                        end
                    end
                    STOP: begin
                        if (oversample_count == 4'd15 && sync_ff_2) begin
                            data <= rx_shift_reg;
                        end
                    end
                    default: rx_shift_reg <= 8'd0;
                endcase
            end
        end
    end

    // 7. busy
    assign busy = (state != IDLE);

    // 8. done
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) done <= 1'b0;
        else begin
            done <= 1'b0;
            if (state == STOP && rx_baud_tick && oversample_count == 4'd15 && sync_ff_2)
                done <= 1'b1;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) frame_error <= 1'b0;
        else begin
            frame_error <= 1'b0;
            if (state == STOP && rx_baud_tick && oversample_count == 4'd15 && !sync_ff_2)
                frame_error <= 1'b1;
        end
    end

endmodule
