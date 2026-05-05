`timescale 1ns / 1ps

module count #(
    parameter N = 4,
    localparam N_WIDTH = $clog2(N)
) (
    input wire clk,
    input wire rst_n,
    input wire tick,
    output reg [N_WIDTH-1:0] count
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= {N_WIDTH{1'b0}};
        end else begin
            if (tick) begin
                if (count == N - 1) begin
                    count <= {N_WIDTH{1'b0}};
                end else begin
                    count <= count + 1'b1;  // 0 1 2 3
                end
            end
        end
    end
endmodule
