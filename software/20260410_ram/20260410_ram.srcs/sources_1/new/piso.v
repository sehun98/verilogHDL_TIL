`timescale 1ns / 1ps

module piso (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       load,       // 병렬 데이터 로드
    input  wire       shift_en,   // shift enable
    input  wire [7:0] d,
    output wire       q
);

    reg [7:0] mem;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mem <= 8'b0;
        end else begin
            if (load) begin
                mem <= d;
            end else if (shift_en) begin
                mem <= {1'b0, mem[7:1]};
            end
        end
    end

    assign q = mem[0];

endmodule