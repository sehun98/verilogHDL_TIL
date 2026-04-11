`timescale 1ns / 1ps

module ultrasonic (
    input wire clk,
    input wire rst_n,
    input wire start,
    output reg [9:0] distance, // 0~1023
    // 450cm 기준 450 = time * 0.034 / 2
    // 26470us / 0.01 = 2647000 count

    output wire  trig,
    input  wire echo
);

    reg [2:0] next_state, state;

    localparam IDLE            = 3'b000;
    localparam TRIG            = 3'b001;
    localparam WAIT_ECHO_HIGH  = 3'b010;
    localparam COUNT_ECHO      = 3'b011;
    localparam DONE            = 3'b100;

    localparam ECHO_TIMEOUT = 22'd3_000_000; // 100MHz 기준 30ms
    localparam TRIG_TIME    = 20'd999;       // 100MHz 기준 10us

    wire trig_done;
    wire echo_check;
    wire echo_timeout;
    wire echo_done;

    reg [19:0] trig_count;
    reg [21:0] wait_count;  // ECHO_TIMEOUT = 3_000_000
    reg [21:0] echo_count;

    // 1. state register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    // 2. next state logic
    always @(*) begin
        next_state = state;

        case (state)
            IDLE: if (start) next_state = TRIG;
            TRIG: if (trig_done) next_state = WAIT_ECHO_HIGH;
            WAIT_ECHO_HIGH: begin
                if (echo_check)
                    next_state = COUNT_ECHO;
                else if (echo_timeout)
                    next_state = IDLE;
            end

            COUNT_ECHO: if (echo_done) next_state = DONE;
            DONE: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

    // 3. datapath
    // TRIG 상태에서 10us 송신이 끝났는지
    assign trig_done = (state == TRIG) && (trig_count >= TRIG_TIME);
    // WAIT_ECHO_HIGH 상태에서 echo가 high가 되었는지
    assign echo_check = (state == WAIT_ECHO_HIGH) && echo;
    // WAIT_ECHO_HIGH 상태에서 너무 오래 기달렸는지 (30ms정도)
    assign echo_timeout = (state == WAIT_ECHO_HIGH) && (wait_count >= ECHO_TIMEOUT);
    // COUNT_ECHO 상태에서 echo가 다시 Low가 되었는지
    assign echo_done = (state == COUNT_ECHO) && !echo;

    // 100_000_000Hz = 10ns
    // 10us = 100_000_000Hz / 1000
    // 4. counters
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            trig_count <= 20'd0;
            echo_count <= 22'd0;
            wait_count <= 22'd0;
        end else begin
            case (state)
                TRIG: begin
                    echo_count <= 22'd0;
                    wait_count <= 22'd0;

                    // 10us 동안 trig 유지
                    if (trig_count >= TRIG_TIME) begin
                        trig_count <= 20'd0;
                    end else begin
                        trig_count <= trig_count + 20'd1;
                    end
                end

                WAIT_ECHO_HIGH: begin
                    trig_count <= 20'd0;
                    echo_count <= 22'd0;

                    // echo가 올라올 때까지 대기 시간 카운트
                    if (wait_count >= ECHO_TIMEOUT) begin
                        wait_count <= 22'd0;
                    end else begin
                        wait_count <= wait_count + 22'd1;
                    end
                end

                COUNT_ECHO: begin
                    trig_count <= 20'd0;
                    wait_count <= 22'd0;

                    // echo가 high인 동안만 폭 측정
                    if (echo) begin
                        echo_count <= echo_count + 22'd1;
                    end else begin
                        echo_count <= echo_count;  // 값 유지
                    end
                end

                default: begin
                    trig_count <= 20'd0;
                    echo_count <= 22'd0;
                    wait_count <= 22'd0;
                end
            endcase
        end
    end

    // 5. output logic
    assign trig = (state == TRIG);

    // 6. distance register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            distance <= 8'd0;
        end else if (state == DONE) begin
            // 100MHz 기준 10ns
            // 1. distance <= (echo_count * 0.01 * 0.034) / 2;
            // 2. distance <= echo_count * 0.00017;
            // 3. distance <= echo_count * 17 / 100000;
            // 4. distance <= echo_count / 5882;
            // WTS 문제 발생
            // 5. distance ≈ (echo_count * K) >> S 근사화 진행
            // K = 2^S / 5882
            // S = 20, K = 178
            distance <= (echo_count * 179) >> 20;
            // 정확도 확인
            // 178 / 1048576 = 0.0001697540283203125
            // 1 / 5882 = 0.00017001020061203672220333
            // 오차 0.0015%
        end
    end
endmodule
