`timescale 1ns / 1ps

module apb_fnd (
    input  logic        PCLK,
    input  logic        PRESETn,

    input  logic        PSEL,
    input  logic        PENABLE,
    input  logic        PWRITE,
    input  logic [3:0]  PSTRB,
    input  logic [31:0] PADDR,
    input  logic [31:0] PWDATA,

    output logic [31:0] PRDATA,
    output logic        PREADY,
    output logic        PSLVERR,

    output logic [3:0]  digit,
    output logic [7:0]  seg
);

    logic apb_access;
    logic apb_write;
    logic apb_read;

    logic [13:0] fnd_data;
    logic        fnd_on_off;

    assign apb_access = PSEL & PENABLE;
    assign apb_write  = apb_access & PWRITE;
    assign apb_read   = apb_access & ~PWRITE;

    assign PREADY  = 1'b1;
    assign PSLVERR = 1'b0;

    fnd u_fnd (
        .clk        (PCLK),
        .rst_n      (PRESETn),
        .fnd_data   (fnd_data),
        .fnd_on_off (fnd_on_off),
        .digit      (digit),
        .seg        (seg)
    );

    always_ff @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            fnd_on_off <= 1'b0;
            fnd_data   <= 14'd0;
        end else if (apb_write) begin
            case (PADDR[7:0])
                8'h00: begin
                    if (PSTRB[0])
                        fnd_on_off <= PWDATA[0];
                end
                8'h04: begin
                    if (PSTRB[0])
                        fnd_data[7:0] <= PWDATA[7:0];

                    if (PSTRB[1])
                        fnd_data[13:8] <= PWDATA[13:8];
                end
            endcase
        end
    end
    always_comb begin
        PRDATA = 32'd0;
        if (apb_read) begin
            case (PADDR[7:0])
                8'h00: PRDATA = {31'd0, fnd_on_off};
                8'h04: PRDATA = {18'd0, fnd_data};
                default: PRDATA = 32'd0;
            endcase
        end
    end
endmodule

module fnd (
    input logic clk,
    input logic rst_n,

    input logic [13:0] fnd_data,
    input logic        fnd_on_off,

    output logic [3:0] digit,
    output logic [7:0] seg
);
    logic       w_tick;
    logic [1:0] w_count;
    logic [3:0] w_digit_1;
    logic [3:0] w_digit_10;
    logic [3:0] w_digit_100;
    logic [3:0] w_digit_1000;
    logic [3:0] w_digit_out;

    logic [13:0] w_fnd_data;

    assign w_fnd_data = fnd_on_off ? fnd_data : 14'd0;

    tick_1ms u1_tick_1ms (
        .clk       (clk),
        .rst_n     (rst_n),
        .tick      (w_tick)
    );
    count4 u2_count4 (
        .clk  (clk),
        .rst_n(rst_n),
        .tick (w_tick),
        .count(w_count)
    );
    decode2to4 u3_decode2to4 (
        .count(w_count),
        .digit(digit)
    );
    bcd u4_bcd (
        .digit(w_digit_out),
        .seg  (seg)
    );
    mux4to1 u5_mux4to1 (
        .digit_1   (w_digit_1),
        .digit_10  (w_digit_10),
        .digit_100 (w_digit_100),
        .digit_1000(w_digit_1000),
        .count     (w_count),
        .digit_out (w_digit_out)
    );
    digit_split u6_digit_split (
        .data      (w_fnd_data),
        .digit_1   (w_digit_1),
        .digit_10  (w_digit_10),
        .digit_100 (w_digit_100),
        .digit_1000(w_digit_1000)
    );
endmodule

module tick_1ms (
    input  logic clk,
    input  logic rst_n,
    output logic tick
);
    localparam CLOCK_FREQ_HZ = 100_000_000;
    localparam COUNT = CLOCK_FREQ_HZ / 1000;
    localparam COUNT_WIDTH = $clog2(COUNT);

    logic [COUNT_WIDTH-1:0] cnt;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt  <= 0;
            tick <= 1'd0;
        end else begin
            if (cnt == COUNT - 1) begin
                cnt  <= 0;
                tick <= 1'd1;
            end else begin
                cnt  <= cnt + 1'd1;
                tick <= 1'd0;
            end
        end
    end
endmodule

module count4 (
    input logic clk,
    input logic rst_n,
    input logic tick,
    output logic [1:0] count
);
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= 2'd0;
        end else begin
            if (tick) begin
                count <= count + 1'd1;
            end
        end
    end
endmodule

module decode2to4 (
    input  logic [1:0] count,
    output logic [3:0] digit
);
    always_comb begin
        digit = 4'b1111;
        case (count)
            2'd0: digit = 4'b1110;
            2'd1: digit = 4'b1101;
            2'd2: digit = 4'b1011;
            2'd3: digit = 4'b0111;
        endcase
    end
endmodule

module bcd (
    input  logic [3:0] digit,  // 0~16
    output logic [7:0] seg
);
    always_comb begin
        case (digit)
            4'h0: seg = 8'b1100_0000;
            4'h1: seg = 8'b1111_1001;
            4'h2: seg = 8'b1010_0100;
            4'h3: seg = 8'b1011_0000;
            4'h4: seg = 8'b1001_1001;
            4'h5: seg = 8'b1001_0010;
            4'h6: seg = 8'b1000_0010;
            4'h7: seg = 8'b1111_1000;
            4'h8: seg = 8'b1000_0000;
            4'h9: seg = 8'b1001_0000;

            4'hA: seg = 8'b1000_1000;
            4'hB: seg = 8'b1000_0011;
            4'hC: seg = 8'b1100_0110;
            4'hD: seg = 8'b1010_0001;
            4'hE: seg = 8'b1000_0110;
            4'hF: seg = 8'b1000_1110;

            default: seg = 8'hFF;
        endcase
    end
endmodule

module mux4to1 (
    input  logic [3:0] digit_1,
    input  logic [3:0] digit_10,
    input  logic [3:0] digit_100,
    input  logic [3:0] digit_1000,
    input  logic [1:0] count,
    output logic [3:0] digit_out
);
    always_comb begin
        case (count)
            2'd0: digit_out = digit_1;
            2'd1: digit_out = digit_10;
            2'd2: digit_out = digit_100;
            2'd3: digit_out = digit_1000;
        endcase
    end
endmodule

module digit_split (
    input  logic [13:0] data,
    output logic [ 3:0] digit_1,
    output logic [ 3:0] digit_10,
    output logic [ 3:0] digit_100,
    output logic [ 3:0] digit_1000
);
    assign digit_1 = data % 10;
    assign digit_10 = (data / 10) % 10;
    assign digit_100 = (data / 100) % 10;
    assign digit_1000 = (data / 1000);
endmodule
