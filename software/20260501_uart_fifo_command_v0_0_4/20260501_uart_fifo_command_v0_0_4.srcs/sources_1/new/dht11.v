`timescale 1ns / 1ps

// dht11에 fnd랑 btn이 모두 있으면 X
// top_stopwatch에서 연결됨.
module dht11 (
    input clk,
    input rst_n,

    input dht11_start, // uart tx controller에서 dht11 데이터 요청 신호
    output dht11_done, // uart tx controller로 보내는 읽으라는 pulse 신호

    output [7:0] humidity,  // uart tx controller로 보내는 데이터
    output [7:0] temperature,  // uart tx controller로 보내는 데이터
    inout dht11  // 입출력 라인
);
    dht11_controller U_DHT11_CNT (
        .clk(clk),
        .rst_n(rst_n),
        .tick_us(tick_us),
        .dht11_start(dht11_start),
        .dht11_done(dht11_done),
        .humidity(humidity),
        .temperature(temperature),
        .dht11(dht11)
    );

    tick_gen_us U_TICK_GEN (
        .clk(clk),
        .rst_n(rst_n),
        .tick_us(tick_us)
    );


endmodule

// valid 가 1일 경우에면 done신호가 발생해야되고 외부로 valid를 보낼 필요가 없어짐.
module dht11_controller (
    input clk,
    input rst_n,
    input tick_us,

    input      dht11_start,
    output wire dht11_done,

    //output       valid,
    output [7:0] humidity,
    output [7:0] temperature,
    inout        dht11
);
    parameter IDLE = 0, START = 1, WAIT = 2, SYNCH = 4, SYNCL = 3;
    parameter DATA_SYNC = 5, DATA_COUNT = 6, DATA_DECISION = 7;
    parameter STOP = 8;


    reg [3:0] c_state, n_state;
    reg [5:0] bit_cnt_reg, bit_cnt_next;  // receive bit counter
    reg [$clog2(19_000)-1:0]
        tick_cnt_reg, tick_cnt_next;  // general tick count //prepare over 18ms
    reg out_sel_reg, out_sel_next;  // dht11 io 3state control
    reg dht11_reg, dht11_next;  // dht11 output drive

    reg [39:0] data_reg, data_next;

    assign dht11 = (out_sel_reg) ? dht11_reg : 1'bz;


    reg dht11_done_reg;
    wire valid = data_reg[7:0]==(data_reg[39:32] + data_reg[31:24] + data_reg[23:16] + data_reg[15:8]) ? 1 : 0;
    //check sum 처리 해야됨!
    assign dht11_done = dht11_done_reg & valid & (data_reg[39:32] != 0 &&  data_reg[23:16] != 0);

    assign humidity = data_reg[39:32];
    assign temperature = data_reg[23:16];

    // 1. 동기화를 위한 레지스터 선언
    reg dht11_sync_1, dht11_sync_2;
    wire dht11_clean;

    // 2. 2-stage FF 로직 (시스템 메인 클럭 사용)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dht11_sync_1 <= 1'b1; // DHT11은 기본적으로 Pull-up 상태이므로 1로 초기화
            dht11_sync_2 <= 1'b1;
        end else begin
            dht11_sync_1 <= dht11;      // 첫 번째 스테이지: 비동기 신호 샘플링
            dht11_sync_2 <= dht11_sync_1; // 두 번째 스테이지: 안정화된 신호 전달
        end
    end

    // 3. 필터링된 깨끗한 신호를 사용
    assign dht11_clean = dht11_sync_2;

    always @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            c_state      <= IDLE;
            bit_cnt_reg  <= 0;
            tick_cnt_reg <= 0;
            out_sel_reg  <= 1'b1;  // default output mode
            dht11_reg    <= 1'b1;  // default high state
            data_reg     <= 0;
        end else begin
            c_state      <= n_state;
            bit_cnt_reg  <= bit_cnt_next;
            tick_cnt_reg <= tick_cnt_next;
            out_sel_reg  <= out_sel_next;  // when idle dht11 output mode
            dht11_reg    <= dht11_next;  // default high state
            data_reg     <= data_next;
        end
    end

    always @(*) begin
        n_state       = c_state;
        bit_cnt_next  = bit_cnt_reg;
        tick_cnt_next = tick_cnt_reg;
        out_sel_next  = out_sel_reg;
        dht11_next    = dht11_reg;
        data_next     = data_reg;
        dht11_done_reg    = 0;
        case (c_state)
            IDLE: begin  //0
                dht11_done_reg   = 0;
                dht11_next   = 1'b1;
                out_sel_next = 1'b1;
                if (dht11_start) begin
                    tick_cnt_next = 0;
                    bit_cnt_next = 0;
                    n_state = START;
                end
            end

            START: begin  //1
                dht11_next = 1'b0;
                dht11_done_reg = 0;
                if (tick_us) begin
                    if (tick_cnt_reg > 19_000) begin
                        n_state = WAIT;
                        tick_cnt_next = 0;
                    end else begin
                        tick_cnt_next = tick_cnt_reg + 1;
                    end
                end
            end

            WAIT: begin  //2
                dht11_next = 1'b1;
                dht11_done_reg = 0;
                if (tick_us) begin
                    if (tick_cnt_reg > 30) begin
                        tick_cnt_next = 0;
                        n_state = SYNCL;
                    end else begin
                        tick_cnt_next = tick_cnt_reg + 1;
                    end
                end
            end

            SYNCL: begin  //3
                //output high impedence 'z'
                out_sel_next = 1'b0;
                dht11_done_reg   = 0;
                if (tick_us) begin
                    if ((tick_cnt_reg > 40) && (dht11_clean)) begin
                        tick_cnt_next = 0;
                        n_state = SYNCH;
                    end else begin
                        tick_cnt_next = tick_cnt_reg + 1;
                    end
                end

            end

            SYNCH: begin  //4
                dht11_done_reg = 0;
                if (tick_us) begin
                    if ((tick_cnt_reg > 40) && (!dht11_clean)) begin
                        tick_cnt_next = 0;
                        n_state = DATA_SYNC;
                    end else begin
                        tick_cnt_next = tick_cnt_reg + 1;
                    end
                end
            end

            DATA_SYNC: begin  //5
                dht11_done_reg = 0;
                if (tick_us) begin
                    if (dht11_clean) begin
                        tick_cnt_next = 0;
                        n_state = DATA_COUNT;
                    end else begin
                        tick_cnt_next = tick_cnt_reg + 1;
                    end
                end
            end

            DATA_COUNT: begin  //6
                dht11_done_reg = 0;
                if (tick_us) begin
                    if (!dht11_clean) begin
                        n_state = DATA_DECISION;
                    end else begin
                        tick_cnt_next = tick_cnt_reg + 1;
                    end
                end
            end

            DATA_DECISION: begin  //7
                // data _ reg 40bit
                dht11_done_reg = 0;
                if (tick_cnt_reg <= 40) begin
                    data_next = {data_reg[38:0], 1'b0};
                end else begin
                    data_next = {data_reg[38:0], 1'b1};
                end

                if (bit_cnt_reg == 39) begin
                    n_state = STOP;
                    bit_cnt_next = 0;
                    tick_cnt_next = 0;
                end else begin
                    bit_cnt_next = bit_cnt_reg + 1;
                    tick_cnt_next = 0;
                    n_state = DATA_SYNC;
                end

            end

            STOP: begin  //8
                if (tick_us) begin
                    if (tick_cnt_reg > 50) begin
                        tick_cnt_next = 0;
                        n_state = IDLE;
                        dht11_done_reg = 1;
                    end else begin
                        tick_cnt_next = tick_cnt_reg + 1;
                    end
                end
            end

            //default: 
        endcase

    end
endmodule

module tick_gen_us (
    input clk,
    input rst_n,
    output reg tick_us
);
    parameter F_COUNT = (100_000_000 / 1_000_000);
    reg [$clog2(F_COUNT)-1:0] counter_reg;

    always @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            counter_reg <= 0;
            tick_us <= 1'b0;
        end else begin
            counter_reg <= counter_reg + 1;
            if (counter_reg == (F_COUNT - 1)) begin
                counter_reg <= 0;
                tick_us <= 1'b1;
            end else begin
                tick_us <= 0;
            end
        end
    end

endmodule
