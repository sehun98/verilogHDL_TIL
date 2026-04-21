`timescale 1ns / 1ps

module uart_tx_counter (
    input        clk,
    input        rst_n,
    input        tx_start,
    input  [7:0] tx_data,
    input        b_tick,
    output       tx
);

    parameter IDLE = 0;
    parameter WAIT = 1;
    parameter START = 2;
    parameter DATA = 3;
    parameter STOP = 4;

    reg [3:0] c_state, n_state;
    reg tx_reg, tx_next;  //순차출력으로 진행하니까
    //tx data register
    reg [7:0] data_reg, data_next;  //data 저장하는 레지스터

    reg [2:0] bit_count_reg, bit_count_next;

    assign tx = tx_reg;

    always @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            c_state <= IDLE;
            tx_reg <= 1'b1;  //1이니까 preset이라고 뜸
            data_reg <= 8'h00;
            bit_count_reg <= 2'b00;
        end else begin
            c_state <= n_state;
            tx_reg    <= tx_next; //reg는 next 업데이트, next를 output 관리하는 곳에서 출력
            data_reg <= data_next;
            bit_count_reg <= bit_count_next;
        end
    end

    //next st CL, output
    always @(*) begin
        n_state = c_state;
        tx_next = tx_reg;
        data_next = data_reg;
        bit_count_next = bit_count_reg;
        case (c_state)
            IDLE: begin  // 0
                tx_next = 1'b1;
                if (tx_start == 1) begin
                    data_next = tx_data;
                    n_state   = WAIT;
                end
            end

            WAIT: begin  // 1
                if (b_tick) begin
                    n_state = START;
                end
            end

            START: begin  // 2
                tx_next = 1'b0;
                if (b_tick) begin
                    n_state = DATA;
                end
            end

            DATA: begin  // 3
                tx_next = data_reg[bit_count_reg];
                if (b_tick) begin
                    if (bit_count_next == 7) begin  // 0111 1000
                        n_state = STOP;
                        bit_count_next = 0;
                    end else begin
                        bit_count_next = bit_count_next + 1;
                    end
                end
            end

            STOP: begin  // 4
                tx_next = 1'b1;
                if (b_tick) begin
                    n_state = IDLE;
                end
            end

        endcase
    end

endmodule
