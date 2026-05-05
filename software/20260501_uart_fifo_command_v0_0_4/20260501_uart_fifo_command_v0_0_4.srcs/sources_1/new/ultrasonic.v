`timescale 1ns / 1ps

module ultrasonic (
    input wire clk,
    input wire rst_n,
    input wire ultrasonic_start,
    output wire ultrasonic_done,
    output wire [8:0] distance,
    output wire trig,
    input wire echo
);
    wire w_tick_us;

    ultrasonic_controller u1_ultrasonic_controller (
        .clk(clk),
        .rst_n(rst_n),
        .tick_us(w_tick_us),
        .ultrasonic_start(ultrasonic_start),
        .ultrasonic_done(ultrasonic_done),
        .trig(trig),
        .echo(echo),
        .distance(distance)
    );

    ultrasonic_tick_gen u2_ultrasonic_tick_gen (
        .clk(clk),
        .rst_n(rst_n),
        .tick_us(w_tick_us)
    );
endmodule

module ultrasonic_tick_gen #(
    parameter CLOCK_FREQ_HZ = 100_000_000,
    parameter HZ = 1_000_000
) (
    input  wire clk,
    input  wire rst_n,
    output reg  tick_us
);
    localparam CNT = CLOCK_FREQ_HZ / HZ;
    localparam CNT_WIDTH = $clog2(CNT);
    reg [CNT_WIDTH-1:0] counter_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter_reg <= {CNT_WIDTH{1'b0}};
            tick_us <= 1'b0;
        end else begin
            counter_reg <= counter_reg + 1'b1;
            if (counter_reg == CNT - 1'b1) begin
                counter_reg <= {CNT_WIDTH{1'b0}};
                tick_us <= 1'b1;
            end else begin
                tick_us <= 1'b0;
            end
        end
    end
endmodule

module ultrasonic_controller (
    input wire clk,
    input wire rst_n,
    input wire tick_us,
    input wire ultrasonic_start,
    output wire ultrasonic_done,
    output reg trig,
    input wire echo,
    output wire [8:0] distance
);

    parameter IDLE = 0;
    parameter START = 1;
    parameter WAIT = 2;
    parameter RESPONSE = 3;
    parameter STOP = 4;

    reg [2:0] c_state, n_state;

    reg [15:0] tick_us_cnt_reg, tick_us_cnt_next;
    reg [8:0] distance_reg, distance_next;
    reg [5:0] cm_cnt_reg, cm_cnt_next;

    reg echo_sync_c;
    reg echo_sync_n;
    reg done_reg, done_next;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            echo_sync_c <= 1'b0;
            echo_sync_n <= 1'b0;
        end else begin
            echo_sync_c <= echo;
            echo_sync_n <= echo_sync_c;
        end
    end

    assign distance = distance_reg;
    assign ultrasonic_done = done_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            c_state <= IDLE;
            tick_us_cnt_reg <= 0;
            distance_reg <= 0;
            cm_cnt_reg <= 0;
            done_reg <= 0;
        end else begin
            c_state <= n_state;
            tick_us_cnt_reg <= tick_us_cnt_next;
            distance_reg <= distance_next;
            cm_cnt_reg <= cm_cnt_next;
            done_reg <= done_next;
        end
    end

    always @(*) begin
        n_state          = c_state;
        tick_us_cnt_next = tick_us_cnt_reg;
        distance_next    = distance_reg;
        cm_cnt_next      = cm_cnt_reg;
        done_next        = 1'b0;
        trig             = 1'b0;

        case (c_state)

            IDLE: begin
                if (ultrasonic_start) begin
                    tick_us_cnt_next = 0;
                    distance_next = 0;
                    cm_cnt_next = 0;
                    n_state = START;
                end
            end

            START: begin
                trig = 1'b1;

                if (tick_us) begin
                    tick_us_cnt_next = tick_us_cnt_reg + 1;

                    if (tick_us_cnt_reg >= 11) begin
                        n_state = WAIT;
                        tick_us_cnt_next = 0;
                    end
                end
            end

            WAIT: begin
                if (tick_us) begin
                    if (!echo_sync_n) begin
                        tick_us_cnt_next = tick_us_cnt_reg + 1;

                        if (tick_us_cnt_reg >= 30_000) begin
                            n_state = STOP;
                            tick_us_cnt_next = 0;
                            distance_next = 0;
                            cm_cnt_next = 0;
                        end
                    end else begin
                        n_state = RESPONSE;
                        tick_us_cnt_next = 0;
                        distance_next = 0;
                        cm_cnt_next = 0;
                    end
                end
            end

            RESPONSE: begin
                if (tick_us) begin
                    if (echo_sync_n) begin
                        tick_us_cnt_next = tick_us_cnt_reg + 1;

                        if (cm_cnt_reg == 57) begin
                            cm_cnt_next = 0;
                            if (distance_reg < 511)
                                distance_next = distance_reg + 1;
                        end else begin
                            cm_cnt_next = cm_cnt_reg + 1;
                        end

                        if (tick_us_cnt_reg >= 30_000) begin
                            n_state = STOP;
                            tick_us_cnt_next = 0;
                            cm_cnt_next = 0;
                        end
                    end else begin
                        n_state = STOP;
                        tick_us_cnt_next = 0;
                        cm_cnt_next = 0;
                    end
                end
            end

            STOP: begin
                done_next = 1'b1;
                n_state = IDLE;
            end

        endcase
    end

endmodule