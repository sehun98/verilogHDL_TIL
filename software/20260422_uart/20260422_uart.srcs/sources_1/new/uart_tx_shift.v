`timescale 1ns / 1ps

module uart_tx_shift (
    input        clk,
    input        rst_n,
    input        tx_start,
    input  [7:0] tx_data,
    input        b_tick,
    output       tx
);

    parameter IDLE = 0, WAIT = 1, START = 2;
    parameter BIT0 = 3, BIT1 = 4, BIT2 = 5, BIT3 = 6;
    parameter BIT4 = 7, BIT5 = 8, BIT6 = 9, BIT7 = 10;
    parameter STOP = 11;

    reg [3:0] c_state, n_state;
    reg tx_reg, tx_next;  //순차출력으로 진행하니까
    //tx data register
    reg [7:0] data_reg, data_next;  //data 저장하는 레지스터

    assign tx = tx_reg;

    always @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            c_state  <= IDLE;
            tx_reg   <= 1'b1;  //1이니까 preset이라고 뜸
            data_reg <= 8'h00;
        end else begin
            c_state <= n_state;
            tx_reg    <= tx_next; //reg는 next 업데이트, next를 output 관리하는 곳에서 출력
            data_reg <= data_next;
        end
    end

    //next st CL, output
    always @(*) begin
        n_state = c_state;
        tx_next = tx_reg; //tx output 왜 여기서 초기화하지? output은 밑에서 따로 관리하면서?
        data_next = data_reg;
        case (c_state)
            IDLE: begin
                tx_next = 1'b1;
                if (tx_start == 1) begin
                    data_next = tx_data; //다음 클럭에 업데이트되는지 시뮬에서 확인
                    n_state = WAIT;
                end
            end

            WAIT: begin
                if (b_tick) begin
                    n_state = START;
                end
            end

            START: begin
                tx_next = 1'b0;
                if (b_tick) begin
                    n_state = BIT0;
                end
            end

            BIT0: begin
                tx_next = data_reg[0];  //규칙이 lsb이니까

                if (b_tick) begin
                    n_state = BIT1;
                end
            end

            BIT1: begin
                tx_next = data_reg[1];

                if (b_tick) begin
                    n_state = BIT2;
                end
            end

            BIT2: begin
                tx_next = data_reg[2];

                if (b_tick) begin
                    n_state = BIT3;
                end
            end

            BIT3: begin
                tx_next = data_reg[3];
                if (b_tick) begin
                    n_state = BIT4;
                end
            end

            BIT4: begin
                tx_next = data_reg[4];
                if (b_tick) begin
                    n_state = BIT5;
                end
            end

            BIT5: begin
                tx_next = data_reg[5];
                if (b_tick) begin
                    n_state = BIT6;
                end
            end

            BIT6: begin
                tx_next = data_reg[6];
                if (b_tick) begin
                    n_state = BIT7;
                end
            end

            BIT7: begin
                tx_next = data_reg[7];
                if (b_tick) begin
                    n_state = STOP;
                end
            end

            STOP: begin
                tx_next = 1'b1;
                if (b_tick) begin
                    n_state = IDLE;
                end
            end

        endcase
    end

endmodule
