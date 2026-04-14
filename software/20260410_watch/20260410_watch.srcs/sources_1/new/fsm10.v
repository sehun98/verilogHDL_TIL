`timescale 1ns / 1ps

module fsm10 (
    input  clk,
    input  rst,
    input  din_bit,
    output dout_bit
);

    reg [2:0] state_reg, next_state;

    // 상태 선언
    parameter start = 3'b000;
    parameter rd0_once = 3'b001;
    parameter rd1_once = 3'b010;
    parameter rd0_twice = 3'b011;
    parameter rd1_twice = 3'b100;

    // 다음 상태 결정을 위한 조합회로
    always @(state_reg or din_bit) begin
        case (state_reg)

            start: begin
                if (din_bit == 0) next_state = rd0_once;
                else if (din_bit == 1) next_state = rd1_once;
                else next_state = start;
            end

            rd0_once: begin
                if (din_bit == 0) next_state = rd0_twice;
                else if (din_bit == 1) next_state = rd1_once;
                else next_state = start;
            end

            rd0_twice: begin
                if (din_bit == 0) next_state = rd0_twice;
                else if (din_bit == 1) next_state = rd1_once;
                else next_state = start;
            end

            rd1_once: begin
                if (din_bit == 0) next_state = rd0_once;
                else if (din_bit == 1) next_state = rd1_twice;
                else next_state = start;
            end

            rd1_twice: begin
                if (din_bit == 0) next_state = rd0_once;
                else if (din_bit == 1) next_state = rd1_twice;
                else next_state = start;
            end

            default: begin
                next_state = start;
            end

        endcase
    end

    always @(posedge clk or posedge rst) begin
        if (rst == 1) state_reg <= start;
        else state_reg <= next_state;
    end

    assign dout_bit = (((state_reg == rd0_twice) && (din_bit == 0) || (state_reg == rd1_twice) && (din_bit == 1))) ? 1 : 0;

endmodule

module fsm11 (
    input  clk,
    input  rst,
    input  din_bit,
    output dout_bit
);

    reg [2:0] state_reg, next_state;

    // 상태 선언
    parameter start = 3'b000;
    parameter rd0_once = 3'b001;
    parameter rd1_once = 3'b010;
    parameter rd0_twice = 3'b011;
    parameter rd1_twice = 3'b100;

    // 다음 상태 결정을 위한 조합회로
    always @(state_reg or din_bit) begin
        case (state_reg)

            start: begin
                if (din_bit == 0) next_state = rd0_once;
                else if (din_bit == 1) next_state = rd1_once;
                else next_state = start;
            end

            rd0_once: begin
                if (din_bit == 0) next_state = rd0_twice;
                else if (din_bit == 1) next_state = rd1_once;
                else next_state = start;
            end

            rd0_twice: begin
                if (din_bit == 0) next_state = rd0_twice;
                else if (din_bit == 1) next_state = rd1_once;
                else next_state = start;
            end

            rd1_once: begin
                if (din_bit == 0) next_state = rd0_once;
                else if (din_bit == 1) next_state = rd1_twice;
                else next_state = start;
            end

            rd1_twice: begin
                if (din_bit == 0) next_state = rd0_once;
                else if (din_bit == 1) next_state = rd1_twice;
                else next_state = start;
            end

            default: begin
                next_state = start;
            end

        endcase
    end

    always @(posedge clk or posedge rst) begin
        if (rst == 1) state_reg <= start;
        else state_reg <= next_state;
    end

    assign dout_bit = ((state_reg == rd0_twice) || (state_reg == rd1_twice)) ? 1 : 0;

    //    assign dout_bit = (((state_reg == rd0_twice) && (din_bit == 0) || (state_reg == rd1_twice) && (din_bit == 1))) ? 1 : 0;

endmodule
