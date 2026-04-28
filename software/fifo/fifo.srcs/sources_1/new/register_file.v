`timescale 1ns / 1ps

// read latency 1 clock register
module register_file_1_latency #(
    parameter  REG_SIZE  = 4,
    localparam ADDR_SIZE = $clog2(REG_SIZE)
) (
    input  wire                 clk,
    input  wire [          7:0] w_data,
    output reg  [          7:0] r_data,
    input  wire [ADDR_SIZE-1:0] w_addr,  // 0~3
    input  wire [ADDR_SIZE-1:0] r_addr,  // 0~3
    input  wire                 w_en,
    input  wire                 r_en
);

    // 4
    reg [7:0] register_file[0:REG_SIZE-1];

    always @(posedge clk) begin
        if (w_en) begin
            register_file[w_addr] <= w_data;
        end
    end

    always @(posedge clk) begin
        if (r_en) begin
            r_data <= register_file[r_addr];
        end
    end

endmodule

module register_file_no_latency #(
    parameter  REG_SIZE  = 4,
    localparam ADDR_SIZE = $clog2(REG_SIZE)
) (
    input  wire                 clk,
    input  wire [          7:0] w_data,
    output wire [          7:0] r_data,
    input  wire [ADDR_SIZE-1:0] w_addr,  // 0~3
    input  wire [ADDR_SIZE-1:0] r_addr,  // 0~3
    input  wire                 w_en
);

    // 4
    reg [7:0] register_file[0:REG_SIZE-1];

    always @(posedge clk) begin
        if (w_en) begin
            register_file[w_addr] <= w_data;
        end
    end

    assign r_data = register_file[r_addr];

endmodule

