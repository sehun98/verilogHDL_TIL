`timescale 1ns / 1ps

module uart_tx (
    input wire clk,
    input wire rst_n,
    input wire tx_baud_tick,

    input wire send,
    output wire busy,
    output wire done,
    output wire overrun_error,

    input wire [7:0] tx_data,
    output wire tx
);

    parameter IDLE = 2'b00;
    parameter START = 2'b01;
    parameter DATA = 2'b10;
    parameter STOP = 2'b11;

    reg [1:0] state, n_state;

    reg send_d;
    wire send_pulse = send & ~send_d;

    reg [2:0] count;

    // 1. state register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
        end else begin
            state <= n_state;
        end
    end


    // 2-1. send rising edge detector
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            send_d <= 0;
        end else begin
            send_d <= send;
        end
    end

    assign send_pulse 


    // 2. next state combinational logic
    always @(*) begin
        n_state = state;
        case (state)
            IDLE:  if (send_pulse) n_state = START;
            START: if (tx_baud_tick) n_state = DATA;
            DATA:  if (tx_baud_tick && count == 7) n_state = STOP;
            STOP:  n_state = IDLE;
        endcase
    end

    // 3. count
    always @(*) begin
        if (tx_baud_tick) begin
            case (state)
                DATA:
                if (count == 7) count = 0;
                else count = count + 1;
                default: count = 0;
            endcase
        end
    end

    reg [7:0] tx_data_reg;

    reg [7:0] tx_reg;

    // 4.1 
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin

        end else begin

        end
    end


    // 4.  output combinational logic
    always @(*) begin
        if (tx_baud_tick) begin
            case (state)
                IDLE:  tx_reg = 1;
                START: tx_reg = 0;
                DATA:  tx_reg = tx_data_reg[count];
                STOP:  tx_reg = 1;
            endcase
        end
    end

endmodule
