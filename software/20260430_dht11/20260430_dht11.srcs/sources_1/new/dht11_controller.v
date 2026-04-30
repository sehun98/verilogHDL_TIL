`timescale 1ns / 1ps

module dht11 (
    input wire clk,
    input wire rst_n,
    input wire btn_R,
    output wire [3:0] fnd_com,
    output wire [7:0] fnd_data,
    inout wire dht11
);

endmodule



module dht11_controller (
    input wire clk,
    input wire rst_n,
    input wire tick,
    input wire dht11_start,
    output wire [7:0] temperature,
    output wire [7:0] humidity,
    output wire valid,
    inout wire dht11
);


    localparam IDLE = 4'd0;
    localparam START = 4'd1;
    localparam WAIT = 4'd2;
    localparam SYNC_L = 4'd3;
    localparam SYNC_H = 4'd4;
    localparam DATA_SYNC = 4'd5;
    localparam DATA_CNT = 4'd6;
    localparam DATA_DECISION = 4'd7;
    localparam STOP = 4'd8;

    reg out_sel_reg, out_sel_next;

    reg dht11_reg, dht11_next;

    reg [3:0] state, n_state;
    // bit cnt 0~40
    reg [5:0] bit_cnt_reg, bit_cnt_next;

    // 40bit
    reg [39:0] data_reg, data_next;
    // tick cnt 0~80
    reg [$clog2(18_000)-1:0] tick_cnt_reg, tick_cnt_next;

    // dht11 output 3state control
    assign dht11 = (out_sel_reg) ? dht11_reg : 1'bz;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            bit_cnt_reg <= 0;
            tick_cnt_reg <= 0;
            out_sel_reg <= 1'b1;  // When IDLE dht11 output mode
            dht11_reg <= 1'b1;
            data_reg <= 0;
        end else begin
            state <= n_state;
            bit_cnt_reg <= bit_cnt_next;
            tick_cnt_reg <= tick_cnt_next;
            out_sel_reg <= out_sel_next;
            dht11_reg <= dht11_next;
            data_reg <= data_next;
        end
    end

    assign humidity = data_reg[39:32];
    assign temperature = data_reg[23:16];
    assign valid = (data_reg[7:0]==(data_reg[39:32] + data_reg[31:24] + data_reg[23:16] + data_reg[15:8])) ? 1:0;

    always @(*) begin
        n_state = state;
        bit_cnt_next = bit_cnt_reg;
        tick_cnt_next = tick_cnt_reg;
        out_sel_next = out_sel_reg;
        dht11_next = dht11_reg;
        data_next = data_reg;

        case (state)
            IDLE: begin
                out_sel_next = 1'b1;
                dht11_next   = 1'b1;
                if (dht11_start) begin
                    n_state = START;
                    bit_cnt_next = 0;
                    tick_cnt_next = 0;
                end
            end
            START: begin
                dht11_next = 1'b0;
                if (tick) begin
                    if (tick_cnt_reg >= 19_000) begin
                        n_state = WAIT;
                        tick_cnt_next = 0;
                    end else begin
                        tick_cnt_next = tick_cnt_reg + 1'b1;
                    end
                end
            end
            WAIT: begin
                dht11_next = 1;
                if (tick) begin
                    if (tick_cnt_reg > 30) begin
                        n_state = SYNC_L;
                        tick_cnt_next = 0;
                    end else begin
                        tick_cnt_next = tick_cnt_reg + 1'b1;
                    end
                end
            end
            SYNC_L: begin
                out_sel_next = 1'b0;
                if (tick) begin
                    if (tick_cnt_reg > 40 && dht11_reg) begin
                        n_state = SYNC_H;
                        tick_cnt_next = 0;
                    end else begin
                        tick_cnt_next = tick_cnt_reg + 1'b1;
                    end
                end
            end
            SYNC_H: begin
                out_sel_next = 1'b0;
                if (tick) begin
                    if (tick_cnt_reg > 40 && !dht11_reg) begin
                        n_state = DATA_SYNC;
                        tick_cnt_next = 0;
                    end else begin
                        tick_cnt_next = tick_cnt_reg + 1'b1;
                    end
                end
            end
            DATA_SYNC: begin
                if (tick) begin
                    if (dht11_reg) begin
                        n_state = DATA_CNT;
                        tick_cnt_next = 0;
                    end else begin
                        tick_cnt_next = tick_cnt_reg + 1'b1;
                    end
                end
            end
            DATA_CNT: begin
                if (tick) begin
                    if (!dht11_reg) begin
                        n_state = DATA_DECISION;
                        tick_cnt_next = 0;
                    end else begin
                        tick_cnt_next = tick_cnt_reg + 1'b1;
                    end
                end
            end
            // 수정 &&&&&&&&&&&&&&&&&&&&&&&&& sync 추가도
            // valid 외부로
            DATA_DECISION: begin
                bit_cnt_next = bit_cnt_reg + 1;
                if (bit_cnt_reg == 39) begin
                    n_state = STOP;
                end
            end
            STOP: begin
                if (tick) begin
                    if (tick_cnt_reg > 50) begin
                        n_state = IDLE;
                        tick_cnt_next = 0;
                        out_sel_next = 1;
                    end else begin
                        tick_cnt_next = tick_cnt_reg + 1;
                    end
                end
            end
            default: begin

            end
        endcase
    end

endmodule
