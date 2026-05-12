`timescale 1ns / 1ps

module control_unit (
    input  wire clk,
    input  wire rst_n,      // active low reset
    input  wire btn_run,
    input  wire btn_clear,
    input  wire btn_mode,
    output reg  run,
    output reg  clear,
    output reg  mode
);

    localparam [2:0] IDLE = 3'b000;
    localparam [2:0] STOP = 3'b001;
    localparam [2:0] CLEAR = 3'b010;
    localparam [2:0] RUN = 3'b011;
    localparam [2:0] MODE = 3'b100;

    reg [2:0] state, n_state;

    reg run_reg, run_next;
    reg clear_reg, clear_next;
    reg mode_reg, mode_next;

    // 1. state register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) state <= IDLE;
        else state <= n_state;
    end

    // 2. next state combinational logic
    always @(*) begin
        n_state = state;
        run_next = run_reg;
        clear_next = 1'b0;
        mode_next = mode_reg;

        case (state)
            IDLE: begin
                n_state = STOP;
            end

            STOP: begin
                run_next = 1'b0;
                if (btn_clear) n_state = CLEAR;
                else if (btn_mode) n_state = MODE;
                else if (btn_run) n_state = RUN;
            end

            RUN: begin
                run_next = 1'b1;
                if (btn_run) n_state = STOP;
            end

            CLEAR: begin
                n_state = STOP;
                clear_next = 1;
            end

            MODE: begin
                n_state   = STOP;
                mode_next = ~mode_reg;
            end

            default: begin
                n_state = IDLE;
            end
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            run_reg   <= 1'b0;
            mode_reg  <= 1'b0;
            clear_reg <= 1'b0;
        end else begin
            run_reg   <= run_next;
            clear_reg <= clear_next;
            mode_reg  <= mode_next;
        end
    end

    always @(*) begin
        run   = run_reg;
        clear = clear_reg;
        mode  = mode_reg;
    end

endmodule
