`timescale 1ns / 1ps

module line_collector #(
    parameter LINE_MAX = 64
) (
    input  wire                          clk,
    input  wire                          rst_n,

    output reg                           fifo_r_en, // en 신호를 인가하면 fifo로 부터 데이터가 들어온다.
    input  wire [                   7:0] fifo_data, // 읽오는 데이터
    input  wire                          fifo_empty, // high 일 때 비어 있으므로 데이터를 읽지 말아야 한다.

    output reg  [        8*LINE_MAX-1:0] line_data, // 문장이 완성된 데이터를 전송해준다.
    output reg  [$clog2(LINE_MAX+1)-1:0] line_length, // 문장의 길이를 전송해준다.
    output reg                           line_valid, // 문장이 완성되지 않았을 때 valid를 0으로 유지 시킨다, 문장이 전송이 되어도 0이 된다.

    input  wire                          ready // 상대방에게 문장을 보낼 수 있다는 신호가 들어온다.
);

    reg [8*LINE_MAX-1:0] buffer;
    reg [$clog2(LINE_MAX+1)-1:0] count;

    integer i;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            buffer      <= 0;
            line_data   <= 0;
            line_length <= 0;
            line_valid  <= 0;
            fifo_r_en   <= 0;
            count       <= 0;
        end else begin
            fifo_r_en <= 0;

            // parser가 line_data를 가져가면 valid 해제
            // 상대가 ready인지 확인 한다.
            if (line_valid && ready) begin
                line_valid <= 0;
                count      <= 0;
                buffer     <= 0;
            end  // 아직 완료된 line이 없을 때만 fifo 읽기
            else if (!line_valid && !fifo_empty) begin
                fifo_r_en <= 1;

                // line feed
                if (fifo_data == 8'h0D) begin
                    // '\r' 무시
                // carriage return
                end else if (fifo_data != 8'h0A) begin
                    if (count < LINE_MAX) begin
                        buffer[count*8+:8] <= fifo_data;
                        count <= count + 1;
                    end
                end else begin
                    line_data   <= buffer;
                    line_length <= count;
                    line_valid  <= 1;
                end
            end
        end
    end

endmodule
