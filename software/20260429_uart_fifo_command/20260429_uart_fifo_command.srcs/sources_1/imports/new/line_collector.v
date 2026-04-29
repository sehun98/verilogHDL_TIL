`timescale 1ns / 1ps

// 기존 registered read FIFO
// 현재 combinational read FIFO
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

    reg [8*LINE_MAX-1:0] buffer;
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
                        fifo_r_en <= 1'b1;  // 딱 1클럭 pop pulse

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
                                count <= count + 1'b1;
                            end
                        end

                        state <= S_WAIT;
                    end
                end

                S_WAIT: begin
                    state <= S_IDLE;  // 한 클럭 쉬고 다시 읽기
                end
            endcase
        end
    end

endmodule
