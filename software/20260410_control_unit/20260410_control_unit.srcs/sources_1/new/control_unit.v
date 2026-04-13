`timescale 1ns / 1ps

module control_unit (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [2:0] sw,
    output wire       start,
    output wire       clear,
    output wire       mode
);

localparam IDLE  = 2'b00;
localparam START = 2'b01;
localparam STOP  = 2'b10;

reg [1:0] state, n_state;

// 1. state register
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        state <= IDLE;
    else
        state <= n_state;
end

// 2. next state logic (combinational)
always @(*) begin
    n_state = state;

    case (state)
        IDLE: begin
            if (sw[1]) n_state = IDLE;
            else if (sw[0]) n_state = START;
        end

        START: begin
            if (sw[1]) n_state = IDLE;
            else if (!sw[0]) n_state = STOP;
        end

        STOP: begin
            if (sw[1]) n_state = IDLE;
            else if (sw[0]) n_state = START;
        end

        default: n_state = IDLE;
    endcase
end

// sw[0] on : start, off : stop
// sw[1] on : idle
// sw[2] on : up, off : down

// 3. output logic
assign start = (state == START);
assign clear = (state == IDLE);
assign mode  = sw[2];

endmodule