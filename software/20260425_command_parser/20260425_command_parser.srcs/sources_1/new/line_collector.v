`timescale 1ns / 1ps

module line_collector #(
    parameter LINE_MAX = 64
) (
    input  wire                          clk,
    input  wire                          rst_n,

    output reg                           fifo_r_en,
    input  wire [7:0]                    fifo_data,
    input  wire                          fifo_empty,

    output reg  [8*LINE_MAX-1:0]         line_data,
    output reg  [$clog2(LINE_MAX+1)-1:0] line_length,
    output reg                           line_valid
);

    localparam S_IDLE = 2'd0;
    localparam S_WAIT = 2'd1;
    localparam S_READ = 2'd2;

    reg [1:0] state;

    reg [8*LINE_MAX-1:0] buffer;
    reg [$clog2(LINE_MAX+1)-1:0] count;

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
            line_valid <= 1'b0;   // 1클럭 pulse

            case (state)

                // FIFO에 읽기 요청
                S_IDLE: begin
                    if (!fifo_empty) begin
                        fifo_r_en <= 1'b1;
                        state     <= S_WAIT;
                    end
                end

                // FIFO가 r_en을 보고 dout 갱신하는 클럭
                S_WAIT: begin
                    state <= S_READ;
                end

                // 갱신된 fifo_data 처리
                S_READ: begin
                    if (fifo_data == 8'h0D || fifo_data == 8'h0A) begin
                        // CR 또는 LF 입력 시 한 줄 완성
                        // 단, 빈 줄은 무시해서 CRLF 중복 valid 방지
                        if (count != 0) begin
                            line_data   <= buffer;
                            line_length <= count;
                            line_valid  <= 1'b1;

                            buffer <= 0;
                            count  <= 0;
                        end
                    end else begin
                        if (count < LINE_MAX) begin
                            buffer[count*8 +: 8] <= fifo_data;
                            count <= count + 1'b1;
                        end
                    end

                    state <= S_IDLE;
                end

                default: begin
                    state <= S_IDLE;
                end

            endcase
        end
    end

endmodule