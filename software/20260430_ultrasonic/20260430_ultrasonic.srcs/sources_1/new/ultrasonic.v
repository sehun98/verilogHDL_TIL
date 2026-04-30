`timescale 1ns / 1ps

module ultrasonic (
    input wire clk,
    input wire rst_n,

    input wire request,
    output wire trig,
    input wire echo,
    output wire [8:0] distance
);

    wire w_tick;

    ila_0 uila_0 (
        .clk(clk),
        .probe0(echo),
        .probe1(distance)
    );


    ultrasonic_tick_gen #(
        .CLOCK_FREQ_HZ(100_000_000),
        .N(1000_000)
    ) u1_ultrasonic_tick_gen (
        .i_clk  (clk),
        .i_rst_n(rst_n),
        .o_tick (w_tick)
    );

    ultrasonic_controller u1_ultrasonic_controller (
        .clk(clk),
        .rst_n(rst_n),
        .request(request),
        .tick(w_tick),
        .trig(trig),
        .echo(echo),
        .distance(distance)
    );

endmodule

// 1000_000hz
// 1us
module ultrasonic_tick_gen #(
    parameter CLOCK_FREQ_HZ = 100_000_000,
    parameter N = 1000_000
) (
    input  wire i_clk,
    input  wire i_rst_n,
    output reg  o_tick
);
    localparam CNT = CLOCK_FREQ_HZ / N;
    localparam CNT_WIDTH = $clog2(CNT);

    reg [CNT_WIDTH-1:0] cnt;

    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            cnt <= 0;
            o_tick <= 0;
        end else begin
            if (cnt == CNT - 1) begin
                cnt <= 0;
                o_tick <= 1'b1;
            end else begin
                cnt <= cnt + 1;
                o_tick <= 1'b0;
            end
        end
    end

endmodule


module ultrasonic_controller (
    input wire clk,
    input wire rst_n,
    input wire request,
    input wire tick,
    output wire trig,
    input wire echo,
    // 0~400
    output wire [8:0] distance
);

    localparam IDLE = 2'b00;
    localparam START = 2'b01;
    localparam WAIT = 2'b10;
    localparam RESPONSE = 2'b11;

    reg [1:0] state, n_state;

    // 10tick = 10us
    // 400cm * 58 = 23200
    // 32768 
    reg [14:0] cnt_reg, cnt_next;


    reg trig_reg, trig_next;
    reg [8:0] distance_reg, distance_next;

    assign trig = trig_reg;
    assign distance = distance_reg;

    // state register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            cnt_reg <= 0;
            trig_reg <= 0;
            distance_reg <= 0;
        end else begin
            state <= n_state;
            cnt_reg <= cnt_next;
            trig_reg <= trig_next;
            distance_reg <= distance_next;
        end
    end

    // next state combinational logic
    always @(*) begin
        n_state = state;
        cnt_next = cnt_reg;
        trig_next = trig_reg;
        distance_next = distance_reg;
        case (state)
            IDLE: begin
                trig_next = 0;
                //distance = 0;
                if (request) n_state = START;
            end
            START: begin
                trig_next = 1;
                if (tick) begin
                    if (cnt_reg == 10) begin
                        cnt_next  = 0;
                        trig_next = 0;
                        n_state   = WAIT;
                    end else begin
                        cnt_next = cnt_reg + 1;
                    end
                end
            end
            WAIT: begin
                if (tick) begin
                    if (echo) begin
                        n_state  = RESPONSE;
                        cnt_next = 0;
                    end else begin
                        // wait over time error
                        if (cnt_reg == 30 - 1) begin
                            cnt_next = 0;
                            n_state  = IDLE;
                        end else begin
                            cnt_next = cnt_reg + 1;
                        end
                    end
                end
            end
            RESPONSE:
            if (tick) begin
                if (!echo) begin  // 0이면 
                    n_state = IDLE;
                    distance_next = cnt_reg / 58;
                    cnt_next = 0;
                end else begin  // 1이면 
                    cnt_next = cnt_reg + 1;
                end
            end
        endcase
    end

endmodule
