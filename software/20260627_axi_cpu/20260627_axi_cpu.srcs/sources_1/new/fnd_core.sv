`timescale 1ns / 1ps

module fnd_core (
    input logic clk,
    input logic rst_n,

    input  logic [31:0] FND_CR,  // fnd_on_off
    input  logic [31:0] FND_DR,  // fnd_data
    input  logic [31:0] FND_RPR,
    output logic [ 3:0] digit,
    output logic [ 7:0] seg
);
    logic [3:0] w_data_1;
    logic [3:0] w_data_10;
    logic [3:0] w_data_100;
    logic [3:0] w_data_1000;

    logic [3:0] w_data_out;
    logic [1:0] w_count;

    logic [3:0] w_digit;
    logic [7:0] w_seg;

    logic w_tick;

    logic [13:0] w_fnd_data;

    assign w_fnd_data = FND_DR[13:0];

    digit_spliter u1_digit_spliter (
        .fnd_data (w_fnd_data),
        .data_1   (w_data_1),
        .data_10  (w_data_10),
        .data_100 (w_data_100),
        .data_1000(w_data_1000)
    );

    mux4to1 u2_mux4to1 (
        .data_1   (w_data_1),
        .data_10  (w_data_10),
        .data_100 (w_data_100),
        .data_1000(w_data_1000),
        .mux_sel  (w_count),    // 00 01 10 11
        .data_out (w_data_out)
    );

    decode2to4 u3_decode2to4 (
        .count(w_count),
        .digit(w_digit)
    );

    counter u4_counter (
        .clk  (clk),
        .rst_n(rst_n),
        .tick (w_tick),
        .count(w_count)
    );

    tick_gen u5_tick_gen (
        .clk   (clk),
        .rst_n (rst_n),
        .FND_RPR(FND_RPR),
        .tick  (w_tick)
    );

    bcd u6_bcd (
        .data_out(w_data_out),
        .seg     (w_seg)
    );

    always_comb begin
        if (FND_CR[0]) begin
            digit = w_digit;
            seg   = w_seg;
        end else begin
            digit = 4'b1111;  // all digit off, active-low
            seg   = 8'b1111_1111;  // all segment off, active-low
        end
    end
endmodule

module digit_spliter (
    input  logic [13:0] fnd_data,
    output logic [ 3:0] data_1,
    output logic [ 3:0] data_10,
    output logic [ 3:0] data_100,
    output logic [ 3:0] data_1000
);
    always_comb begin
        data_1 = fnd_data % 10;
        data_10 = (fnd_data / 10) % 10;
        data_100 = (fnd_data / 100) % 10;
        data_1000 = (fnd_data / 1000) % 10;
    end
endmodule

module mux4to1 (
    input  logic [3:0] data_1,
    input  logic [3:0] data_10,
    input  logic [3:0] data_100,
    input  logic [3:0] data_1000,
    input  logic [1:0] mux_sel,    // 00 01 10 11
    output logic [3:0] data_out
);
    always_comb begin
        data_out = data_1;
        case (mux_sel)
            2'd0: begin
                data_out = data_1;
            end
            2'd1: begin
                data_out = data_10;
            end
            2'd2: begin
                data_out = data_100;
            end
            2'd3: begin
                data_out = data_1000;
            end
        endcase
    end
endmodule

module decode2to4 (
    input  logic [1:0] count,
    output logic [3:0] digit
);
    always_comb begin
        digit = 4'b1110;
        case (count)
            2'd0: begin
                digit = 4'b1110;
            end
            2'd1: begin
                digit = 4'b1101;
            end
            2'd2: begin
                digit = 4'b1011;
            end
            2'd3: begin
                digit = 4'b0111;
            end
        endcase
    end
endmodule

module counter (
    input  logic       clk,
    input  logic       rst_n,
    input  logic       tick,
    output logic [1:0] count
);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= 2'd0;
        end else begin
            if (tick) begin
                count <= count + 1'b1;
            end
        end
    end
endmodule

module tick_gen (
    input  logic        clk,
    input  logic        rst_n,
    input  logic [31:0] FND_RPR,
    output logic        tick
);
    logic [31:0] cnt;  // 100_000_000
    logic [31:0] threshold;

    always_comb begin
        if (FND_RPR == 0) threshold = 32'd1;
        else threshold = 100_000_000 / FND_RPR;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tick <= 1'b0;
            cnt  <= 32'd0;
        end else begin
            if (cnt == threshold - 1) begin
                tick <= 1'b1;
                cnt  <= 32'd0;
            end else begin
                cnt  <= cnt + 32'b1;
                tick <= 1'b0;
            end
        end
    end
endmodule

module bcd (
    input  logic [3:0] data_out,
    output logic [7:0] seg
);

    always_comb begin
        case (data_out)
            4'd0: seg = 8'b1100_0000;  // 0
            4'd1: seg = 8'b1111_1001;  // 1
            4'd2: seg = 8'b1010_0100;  // 2
            4'd3: seg = 8'b1011_0000;  // 3
            4'd4: seg = 8'b1001_1001;  // 4
            4'd5: seg = 8'b1001_0010;  // 5
            4'd6: seg = 8'b1000_0010;  // 6
            4'd7: seg = 8'b1111_1000;  // 7
            4'd8: seg = 8'b1000_0000;  // 8
            4'd9: seg = 8'b1001_0000;  // 9
            default: seg = 8'b1111_1111;  // all off
        endcase
    end

endmodule
