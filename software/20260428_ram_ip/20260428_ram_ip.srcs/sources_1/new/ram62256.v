`timescale 1ns / 1ps
// address [3:0]
// w_data [7:0]
// we
// re
// clk
// r_data [7:0]

// we : 1 write
// we : 0 read


module ram62256 (
    input  wire       clk,
    input  wire [7:0] addr,
    input  wire [7:0] w_data,
    output reg  [7:0] r_data,
    input  wire       w_e
);
    reg [7:0] mem[0:255];

    always @(posedge clk) begin
        if (w_e) begin
            mem[addr] <= w_data;
        end else begin
            r_data <= mem[addr];
        end
    end

endmodule

module ram62256_2 (
    input  wire       clk,
    input  wire [7:0] addr,
    input  wire [7:0] w_data,
    output wire [7:0] r_data,
    input  wire       w_e
);
    reg [7:0] mem[0:255];

    always @(posedge clk) begin
        if (w_e) begin
            mem[addr] <= w_data;
        end
    end

    assign r_data = (!w_e) ? mem[addr] : 0;


endmodule

module fifo (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [7:0] w_data,
    output reg  [7:0] r_data,
    input  wire       w_e,
    input  wire       r_e,
    output wire       empty,
    output wire       full
);
    reg [7:0] mem[0:3]; // 

    reg [2:0] w_addr;  // 1+wrapping
    reg [2:0] r_addr;  // 1+wrapping

    always @(posedge clk) begin
        if (!rst_n) begin
            w_addr <= 0;
        end else begin
            if (w_e && !full) begin
                mem[w_addr[1:0]] <= w_data;
                w_addr <= w_addr + 1;
            end
        end
    end

    always @(posedge clk) begin
        if (!rst_n) begin
            r_addr <= 0;
        end else begin
            if (r_e && !empty) begin
                r_data <= mem[r_addr[1:0]];
                r_addr <= r_addr + 1;
            end
        end
    end

    assign full  = (w_addr[1:0] == r_addr[1:0]) && (w_addr[2] != r_addr[2]);
    assign empty = (w_addr == r_addr);

endmodule


module fifo_2 (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [7:0] w_data,
    output reg  [7:0] r_data,
    input  wire       w_e,
    output wire       empty,
    output wire       full
);
    reg [7:0] mem[0:3];

    reg [1:0] w_addr_reg, w_addr_next;
    reg [1:0] r_addr_reg, r_addr_next;

    always @(posedge clk) begin
        if (!rst_n) begin
            w_addr_reg <= 0;
        end else begin
            if (w_e && !full) begin
                mem[w_addr[1:0]] <= w_data;
                w_addr <= w_addr + 1;
            end
        end
    end

    always @(posedge clk) begin
        if (!rst_n) begin
            r_addr_reg <= 0;
        end else begin
            if (r_e && !empty) begin
                r_data <= mem[r_addr[1:0]];
                r_addr <= r_addr + 1;
            end
        end
    end

    assign full  = (w_addr[1:0] == r_addr[1:0]) && (w_addr[2] != r_addr[2]);
    assign empty = (w_addr == r_addr);
endmodule

// empty
// full
// empty & full
// 타이밍 변경
// random test