`timescale 1ns / 1ps

// 기존 registered read FIFO
// 현재 combinational read FIFO
// =======================================================
// line_collector
// [동작 구조]
// 1. RX FIFO가 비어 있지 않으면 fifo_r_en을 1클럭 동안 활성화하여 데이터를 읽는다.
// 2. 읽어온 데이터가 줄바꿈 문자(CR: 0x0D 또는 LF: 0x0A)가 아니면 buffer에 저장한다.
// 3. 줄바꿈 문자가 입력되면 현재까지 저장된 buffer 내용을 line_data로 출력한다.
// 4. 동시에 line_length와 line_valid를 갱신하여 command_parser에 한 줄의 명령어가
//    준비되었음을 알린다.
// 5. 한 줄 처리가 완료되면 buffer와 count를 초기화하고 다음 문자열 수신을 대기한다.
// =======================================================
module line_collector #(
    parameter LINE_MAX = 64
) (
    input wire clk,
    input wire rst_n,

    output reg        fifo_r_en,
    input  wire [7:0] fifo_data,
    input  wire       fifo_empty,

    output reg [        8*LINE_MAX-1:0] line_data,
    output reg [$clog2(LINE_MAX+1)-1:0] line_length,
    output reg                          line_valid
);

    reg [        8*LINE_MAX-1:0] buffer;
    reg [$clog2(LINE_MAX+1)-1:0] count;

    localparam S_IDLE = 1'b0;
    localparam S_WAIT = 1'b1;

    reg state;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state       <= S_IDLE;
            fifo_r_en   <= 1'b0;
            line_valid  <= 1'b0;
            line_data   <= 0;
            line_length <= 0;
            buffer      <= 0;
            count       <= 0;
        end else begin
            fifo_r_en  <= 1'b0;
            line_valid <= 1'b0;

            case (state)
                S_IDLE: begin
                    if (!fifo_empty) begin
                        // 딱 1클럭 pop pulse
                        fifo_r_en <= 1'b1;
                        if (fifo_data == 8'h0D || fifo_data == 8'h0A) begin
                            if (count != 0) begin
                                line_data   <= buffer;
                                line_length <= count;
                                line_valid  <= 1'b1;
                                buffer      <= 0;
                                count       <= 0;
                            end
                        end else begin
                            if (count < LINE_MAX) begin
                                buffer[count*8+:8] <= fifo_data;
                                count              <= count + 1'b1;
                            end
                        end
                        state <= S_WAIT;
                    end
                end
                S_WAIT: begin
                    // 한 클럭 쉬고 다시 읽기
                    // combinational read FIFO
                    state <= S_IDLE;
                end
            endcase
        end
    end
endmodule
