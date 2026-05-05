`timescale 1ns / 1ps

module command_executor (
    input wire clk,
    input wire rst_n,

    // to stopwatch and watch and ultrasonic and dht11
    output reg uart_set_en,
    output reg watch_time_request,
    output reg ultrasonic_request,
    output reg dht11_request,

    // to uart tx controller
    output reg  [4:0]                   o_hour_data,   // hour
    output reg  [5:0]                   o_min_data,   // min
    output reg  [5:0]                   o_sec_data,   // sec
    output reg  [6:0]                   o_msec_data,   // msec
    
    // from command parser
    input wire  [15:0]                   i_cmd_data_1,   // hour
    input wire  [15:0]                   i_cmd_data_2,   // min
    input wire  [15:0]                   i_cmd_data_3,   // sec
    input wire  [15:0]                   i_cmd_data_4,   // msec

    // from command parser
    input wire [ 3:0] cmd_type,
    input wire        cmd_valid,

    // to stopwatch and watch
    output reg stopwatch_run,
    output reg stopwatch_clear,
    output reg stopwatch_mode,

    // to uart tx controller
    output reg exec_done,
    output reg error_send
);

    localparam CMD_NOP = 4'd0;
    localparam CMD_STOPWATCH_RUN = 4'd1;
    localparam CMD_STOPWATCH_CLEAR = 4'd2;
    localparam CMD_STOPWATCH_MODE = 4'd3;
    localparam CMD_WATCH_SET = 4'd4;
    localparam CMD_WATCH_TIME = 4'd5; // watch 시간
    localparam CMD_ULTRASONIC = 4'd6;
    localparam CMD_DHT11 = 4'd7;
    
    // 미구현
    localparam CMD_TIME_SEL = 4'd8;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            exec_done       <= 1'b0;
            error_send      <= 1'b0;

            stopwatch_run   <= 1'b0;
            stopwatch_clear <= 1'b0;
            stopwatch_mode  <= 1'b0;

            uart_set_en <= 1'b0;
        end else begin
            exec_done       <= 1'b0;
            error_send      <= 1'b0;

            stopwatch_run   <= 1'b0;  // pulse signal
            stopwatch_clear <= 1'b0;  // pulse signal
            stopwatch_mode  <= 1'b0;

            uart_set_en <= 1'b0;
            watch_time_request <= 1'b0;
            ultrasonic_request <= 1'b0;
            dht11_request <= 1'b0;

            if (cmd_valid) begin
                exec_done <= 1'b1;

                case (cmd_type)

                    CMD_NOP: begin
                        error_send <= 1'b1;
                    end

                    CMD_STOPWATCH_RUN: begin
                        stopwatch_run <= 1'b1;
                    end

                    CMD_STOPWATCH_CLEAR: begin
                        stopwatch_clear <= 1'b1;
                    end

                    CMD_STOPWATCH_MODE: begin
                        stopwatch_mode <= 1'b1;
                    end

                    CMD_TIME_SEL: begin
                        
                    end

                    CMD_WATCH_SET: begin
                        uart_set_en <= 1'b1;
                        o_hour_data <= i_cmd_data_1[4:0]; // hour
                        o_min_data <= i_cmd_data_2[5:0]; // min
                        o_sec_data <= i_cmd_data_3[5:0]; // sec
                        o_msec_data <= i_cmd_data_4[6:0]; // msec
                    end

                    CMD_WATCH_TIME: begin
                        watch_time_request <= 1'b1;
                    end

                    CMD_ULTRASONIC: begin
                        ultrasonic_request <= 1'b1;
                    end

                    CMD_DHT11: begin
                        dht11_request <= 1'b1;
                    end
                    default: begin
                        error_send <= 1'b1;
                    end

                endcase
            end
        end
    end

endmodule
