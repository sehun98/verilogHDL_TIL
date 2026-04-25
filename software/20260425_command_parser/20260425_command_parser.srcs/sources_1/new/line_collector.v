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

    localparam S_IDLE = 1'b0;
    localparam S_READ = 1'b1;

    reg state;

    reg [8*LINE_MAX-1:0] buffer;
    reg [$clog2(LINE_MAX+1)-1:0] count;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state       <= S_IDLE;
            buffer      <= 0;
            line_data   <= 0;
            line_length <= 0;
            line_valid  <= 0;
            fifo_r_en   <= 0;
            count       <= 0;
        end else begin
            fifo_r_en  <= 0;
            line_valid <= 0;   // 1클럭 pulse

            case (state)

                S_IDLE: begin
                    if (!fifo_empty) begin
                        fifo_r_en <= 1'b1;
                        state     <= S_READ;
                    end
                end

                S_READ: begin
                    // 엔터 감지: LF 또는 CR
                    if (fifo_data == 8'h0A || fifo_data == 8'h0D) begin
                        line_data   <= buffer;
                        line_length <= count;
                        line_valid  <= 1'b1;

                        buffer <= 0;
                        count  <= 0;
                    end else begin
                        if (count < LINE_MAX) begin
                            buffer[count*8 +: 8] <= fifo_data;
                            count <= count + 1'b1;
                        end
                    end

                    state <= S_IDLE;
                end

            endcase
        end
    end

endmodule