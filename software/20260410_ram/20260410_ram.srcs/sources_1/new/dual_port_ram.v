`timescale 1ns / 1ps

module dual_port_ram (
    input wire clk,

    // port A
    input wire w_en_a,
    input wire [6:0] w_addr_a,
    input wire [7:0] w_data_a,
    input wire [6:0] r_addr_a,
    output wire [7:0] r_data_a,

    // port B
    input wire w_en_b,
    input wire [6:0] w_addr_b,
    input wire [7:0] w_data_b,
    input wire [6:0] r_addr_b,
    output wire [7:0] r_data_b
);
    // 126
    reg [7:0] mem[0:125];

    // port A
    always @(posedge clk) begin
        // write
        if (w_en_a) begin
            mem[w_addr_a] <= w_data_a;
        end
        r_data_a <= mem[w_addr_a];
    end

    // port B
    always @(posedge clk) begin
        // write
        if (w_en_b) begin
            mem[w_addr_b] <= w_data_b;
        end
        r_data_b <= mem[w_addr_b];
    end

endmodule
