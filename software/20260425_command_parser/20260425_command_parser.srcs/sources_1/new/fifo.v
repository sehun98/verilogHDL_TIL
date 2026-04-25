`timescale 1ns / 1ps

module fifo (
    input  wire       clk,
    input  wire       rst_n,

    input  wire       w_en,
    input  wire [7:0] din,

    input  wire       r_en,
    output reg  [7:0] dout,

    output wire       empty,
    output wire       full
);

    reg [7:0] w_addr;   // [6:0]: addr, [7]: wrap bit
    reg [7:0] r_addr;

    reg [7:0] mem [0:127];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            w_addr <= 8'd0;
        end else begin
            if (w_en && !full) begin
                mem[w_addr[6:0]] <= din;
                w_addr <= w_addr + 1'b1;
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            r_addr <= 8'd0;
            dout   <= 8'd0;
        end else begin
            if (r_en && !empty) begin
                dout <= mem[r_addr[6:0]];
                r_addr <= r_addr + 1'b1;
            end
        end
    end

    assign empty = (w_addr == r_addr);
    assign full  = (w_addr[6:0] == r_addr[6:0]) && (w_addr[7] != r_addr[7]);

endmodule