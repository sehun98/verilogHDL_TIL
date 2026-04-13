`timescale 1ns / 1ps

module fifo (
    input wire clk,
    input wire rst_n,

    input wire [7:0] din,
    input wire w_en,
    
    output reg [7:0] dout,
    input wire r_en,

    output wire empty,
    output wire full
    );

    // 0~15
    reg [7:0] mem [0:15];
    // wrap bit + 3:0
    reg [4:0] w_addr;
    reg [4:0] r_addr;

    // write
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            w_addr <= 5'b0;
        end else begin
            if(w_en && !full) begin
                mem[w_addr[3:0]] <= din;
                w_addr <= w_addr + 1'b1;
            end
        end
    end

    // read
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            r_addr <= 5'b0;
            dout <= 8'b0;
        end else begin
            if(r_en && !empty) begin
                dout <= mem[r_addr[3:0]];
                r_addr <= r_addr + 1'b1;
            end
        end
    end

    assign empty = (w_addr == r_addr);
    assign full = (w_addr[3:0] == r_addr[3:0]) && (w_addr[4] != r_addr[4]);
endmodule
