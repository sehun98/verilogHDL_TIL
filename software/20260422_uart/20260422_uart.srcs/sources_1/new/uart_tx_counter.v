`timescale 1ns / 1ps

module uart_tx_counter (
    input        clk,
    input        rst_n,
    input        tx_start,
    input  [7:0] tx_data,
    input        b_tick,
    output       tx_busy,
    output       tx
);

    parameter IDLE = 0;
    parameter START = 1;
    parameter DATA = 2;
    parameter STOP = 3;

    reg [2:0] c_state, n_state;
    reg tx_reg, tx_next;  //순차출력으로 진행하니까
    //tx data register
    reg [7:0] data_reg, data_next;  //data 저장하는 레지스터

    reg [2:0] bit_cnt_reg, bit_cnt_next;
    reg tx_busy_reg, tx_busy_next;
    reg [3:0] b_tick_cnt_reg, b_tick_cnt_next;

    assign tx = tx_reg;
    assign tx_busy = tx_busy_reg;

    always @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            c_state <= IDLE;
            tx_reg <= 1'b1;  //1이니까 preset이라고 뜸
            data_reg <= 8'h00;
            bit_cnt_reg <= 2'b00;
            b_tick_cnt_reg <= 0;
            tx_busy_reg <= 0;
        end else begin
            c_state <= n_state;
            tx_reg    <= tx_next; //reg는 next 업데이트, next를 output 관리하는 곳에서 출력
            data_reg <= data_next;
            bit_cnt_reg <= bit_cnt_next;
            b_tick_cnt_reg <= b_tick_cnt_next;
            tx_busy_reg <= tx_busy_next;
        end
    end

    //next st CL, output
    always @(*) begin
        n_state = c_state;
        tx_next = tx_reg;
        data_next = data_reg;
        bit_cnt_next = bit_cnt_reg;
        b_tick_cnt_next = b_tick_cnt_reg;
        tx_busy_next = tx_busy_reg;
        case (c_state)
            IDLE: begin  // 0
                tx_busy_next = 0;
                tx_next = 1'b1;
                if (tx_start == 1) begin
                    tx_busy_next = 1'b1;
                    data_next = tx_data;
                    b_tick_cnt_next = 0;
                    n_state = START;
                end
            end

            START: begin  // 1
                tx_next = 1'b0;
                if (b_tick) begin
                    if (b_tick_cnt_reg == 15) begin
                        b_tick_cnt_next = 0;
                        n_state = DATA;
                        bit_cnt_next = 0;
                    end else begin
                        b_tick_cnt_next = bit_cnt_reg + 1;
                    end
                end
            end

            DATA: begin  // 2
                //tx_next = data_reg[bit_count_reg];
                tx_next = data_reg[0];

                if (b_tick) begin
                    if (b_tick_cnt_reg == 15) begin
                        b_tick_cnt_next = 0;
                        if (bit_cnt_next == 7) begin  // 0111 1000
                            n_state = STOP;
                        end else begin
                            data_next = {1'b0, data_reg[7:1]};
                            bit_cnt_next = bit_cnt_next + 1;
                            n_state = DATA;
                        end
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
                end
            end

            STOP: begin  // 3
                tx_next = 1'b1;
                if (b_tick) begin
                    if (b_tick_cnt_reg == 15) begin
                        tx_busy_next = 0;
                        n_state = IDLE;
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
                end
            end

        endcase
    end

endmodule
