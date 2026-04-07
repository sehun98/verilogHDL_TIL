`timescale 1ns / 1ps


module watch_fsm(
    input wire sysclk,
    input wire rst_n, // sw1
    input wire btn_start_noise, // btn1
    input wire btn_stop_noise, // btn2
    input wire btn_reset_noise, // btn3
    output reg [] seg
    );
    parameter CLOCK_FREQ_HZ = 100_000_000;
    parameter DEBOUNCE_MS = 20;

    wire btn_start_debounced;
    wire btn_stop_debounced;
    wire btn_reset_debounced;

    wire btn_start;
    wire btn_stop;
    wire btn_reset;

    // IDLE -> START -> STOP
    // if(btn_start) IDLE -> START
    // if(btn_stop) START -> STOP
    // if(btn_start) STOP -> START
    // if(btn_reset) STOP & START -> IDLE
    integer IDLE = 2'b00;
    integer START = 2'b01;
    integer STOP = 2'b10;

    reg state = IDLE;
    reg next_state = IDLE;

    // 1.state register
    always@(posedge sysclk or negedge rst_n) begin
        if(!rst_n) begin
            next_state <= IDLE;
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    // 2. next_state logic
    always @(posedge sysclk or negedge rst_n) begin
        if(!rst_n) begin
            next_state <= IDLE;
        end else begin
            case (state)
                IDLE : begin
                    if(btn_start) next_state <= START;
                end
                START : begin
                    if(btn_reset) next_state <= IDLE;
                    else if(btn_stop) next_state <= STOP;
                end
                STOP : begin
                    if(btn_start) next_state <= START;
                    else if(btn_reset) next_state <= IDLE; 
                    // overflow 시 stop 추가
                end
                default: next_state <= next_state;
            endcase
        end
    end

    // 3. datapath


    // hardware connection
    debounce #(
        .CLK_FREQ_HZ(CLOCK_FREQ_HZ),
        .DEBOUNCE_MS(DEBOUNCE_MS)
    ) u1_debounce_start (
        .clk(sysclk),
        .rst_n(rst_n),
        .din(btn_start_noise),
        .dout(btn_start_debounced)
    );
    debounce #(
        .CLK_FREQ_HZ(CLOCK_FREQ_HZ),
        .DEBOUNCE_MS(DEBOUNCE_MS)
    ) u2_debounce_stop (
        .clk(sysclk),
        .rst_n(rst_n),
        .din(btn_stop_noise),
        .dout(btn_stop_debounced)
    );
    debounce #(
        .CLK_FREQ_HZ(CLOCK_FREQ_HZ),
        .DEBOUNCE_MS(DEBOUNCE_MS)
    ) u3_debounce_reset (
        .clk(sysclk),
        .rst_n(rst_n),
        .din(btn_reset_noise),
        .dout(btn_reset_debounced)
    );

    rising_edge_detector u1_edge_detector_start (
        .clk(sysclk),
        .rst_n(rst_n),
        .level_in(btn_start_debounced),
        .pulse_out(btn_start)
    );
    rising_edge_detector u2_edge_detector_stop (
        .clk(sysclk),
        .rst_n(rst_n),
        .level_in(btn_stop_debounced),
        .pulse_out(btn_stop)
    );
    rising_edge_detector u3_edge_detector_reset (
        .clk(sysclk),
        .rst_n(rst_n),
        .level_in(btn_reset_debounced),
        .pulse_out(btn_reset)
    );

/*
    n_modulo #(
        .CLK_FREQ_HZ(CLOCK_FREQ_HZ)
    ) u1_1000_modulo (
    input wire clk,
    input wire rst_n,
    input wire count_tick,
    input wire sys_en,
    input wire clear,
    output reg tick,
    output reg [M-1:0] data_out */
);

endmodule
