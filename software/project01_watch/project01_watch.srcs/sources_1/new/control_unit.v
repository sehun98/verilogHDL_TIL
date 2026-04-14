`timescale 1ns / 1ps

module control_unit (
    input  wire clk,
    input  wire rst_n,      // active low reset
    input  wire btn_run,
    input  wire btn_clear,
    input  wire btn_mode,
    output wire run,
    output reg  clear,
    output reg  mode
);

    localparam [2:0] IDLE = 3'b000;
    localparam [2:0] STOP = 3'b001;
    localparam [2:0] CLEAR = 3'b010;
    localparam [2:0] RUN = 3'b011;
    localparam [2:0] MODE = 3'b100;

    reg [2:0] state, n_state;

    // mode 상태를 저장할 레지스터
    reg mode_reg;

    // 1. state register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) state <= IDLE;
        else state <= n_state;
    end

    // 2. next state combinational logic
    always @(*) begin
        n_state = state;
        case (state)
            IDLE: n_state = STOP;
            STOP: begin
                if (btn_clear) n_state = CLEAR;
                else if (btn_mode) n_state = MODE;
                else if (btn_run) n_state = RUN;
                else n_state = STOP;
            end
            RUN: if (btn_run) n_state = STOP;
            CLEAR: n_state = STOP;
            MODE: n_state = STOP;
            default: n_state = IDLE;
        endcase
    end

    // 3. mode register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) mode_reg <= 1'b0;
        else if (state == MODE) mode_reg <= ~mode_reg;
    end

    // 4. output logic
    assign run = (state == RUN);

    always @(*) begin
        clear = (state == CLEAR);
        mode  = mode_reg;
    end

endmodule
