`timescale 1ns / 1ps

module vga_control_unit (
    input logic clk,
    input logic rst_n,

    input logic [3:0] sw_red,
    input logic [3:0] sw_blue,
    input logic [3:0] sw_green,

    output logic h_sync,
    output logic v_sync,

    output logic [3:0] red_port,
    output logic [3:0] blue_port,
    output logic [3:0] green_port
);

    logic w_tick;
    logic [$clog2(800)-1:0] w_hcount;
    logic [$clog2(525)-1:0] w_vcount;
    logic w_display_enable;

    tick_gen #(
        .CLOCK_FREQ_HZ(100_000_000),
        .COUNT(800 * 525 * 60)
    ) u1_tick_gen (
        .clk  (clk),
        .rst_n(rst_n),
        .tick (w_tick)
    );

    pixel_counter #(
        .H_PIXEL(800),
        .V_PIXEL(525)
    ) u2_pixel_counter (
        .clk(clk),
        .rst_n(rst_n),
        .tick(w_tick),
        .hcount(w_hcount),
        .vcount(w_vcount)
    );

    vga_decoder #(
        .H_VISIBLE(640),
        .H_FRONT(16),
        .H_SYNC(96),
        .H_BACK(48),
        .V_VISIBLE(480),
        .V_FRONT(10),
        .V_SYNC(2),
        .V_BACK(33)
    ) u3_vga_decoder (
        .hcount(w_hcount),
        .vcount(w_vcount),
        .h_sync(h_sync),
        .v_sync(v_sync),
        .display_enable(w_display_enable),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel)
    );

    display_data u4_display_data (
        .display_enable(w_display_enable),
        .sw_red(sw_red),
        .sw_green(sw_green),
        .sw_blue(sw_blue),
        .red_port(red_port),
        .green_port(green_port),
        .blue_port(blue_port)
    );

endmodule

// accumulator
module tick_gen #(
    parameter CLOCK_FREQ_HZ = 100_000_000,
    parameter COUNT = (800 * 525 * 60)
) (
    input  logic clk,
    input  logic rst_n,
    output logic tick
);
    localparam COUNT_WIDTH = $clog2(COUNT);
    logic [COUNT_WIDTH+1:0] cnt;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt  <= 0;
            tick <= 1'b0;
        end else begin
            if (cnt + COUNT >= CLOCK_FREQ_HZ) begin
                cnt  <= cnt + COUNT - CLOCK_FREQ_HZ;
                tick <= 1'b1;
            end else begin
                cnt  <= cnt + COUNT;
                tick <= 1'b0;
            end
        end
    end
endmodule

module pixel_counter #(
    parameter H_PIXEL = 800,
    parameter V_PIXEL = 525
) (
    input logic clk,
    input logic rst_n,
    input logic tick,
    output logic [$clog2(H_PIXEL)-1:0] hcount,
    output logic [$clog2(V_PIXEL)-1:0] vcount
);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            hcount <= 0;
            vcount <= 0;
        end else begin
            if (tick) begin
                if (hcount == H_PIXEL - 1) begin
                    hcount <= 0;
                    if (vcount == V_PIXEL - 1) begin
                        vcount <= 0;
                    end else begin
                        vcount <= vcount + 1'b1;
                    end
                end else begin
                    hcount <= hcount + 1'b1;
                end
            end
        end
    end
endmodule

module vga_decoder #(
    parameter int H_VISIBLE = 640,
    parameter int H_FRONT   = 16,
    parameter int H_SYNC    = 96,
    parameter int H_BACK    = 48,

    parameter int V_VISIBLE = 480,
    parameter int V_FRONT   = 10,
    parameter int V_SYNC    = 2,
    parameter int V_BACK    = 33
) (
    input logic [$clog2(H_VISIBLE+H_FRONT+H_SYNC+H_BACK)-1:0] hcount,
    input logic [$clog2(V_VISIBLE+V_FRONT+V_SYNC+V_BACK)-1:0] vcount,

    output logic h_sync,
    output logic v_sync,
    output logic display_enable,

    output logic [$clog2(H_VISIBLE)-1:0] x_pixel,
    output logic [$clog2(V_VISIBLE)-1:0] y_pixel
);

    localparam int H_SYNC_START = H_VISIBLE + H_FRONT;
    localparam int H_SYNC_END = H_VISIBLE + H_FRONT + H_SYNC;

    localparam int V_SYNC_START = V_VISIBLE + V_FRONT;
    localparam int V_SYNC_END = V_VISIBLE + V_FRONT + V_SYNC;

    always_comb begin
        display_enable = (hcount < H_VISIBLE) && (vcount < V_VISIBLE);

        x_pixel = display_enable ? hcount[$clog2(H_VISIBLE)-1:0] : '0;
        y_pixel = display_enable ? vcount[$clog2(V_VISIBLE)-1:0] : '0;

        // VGA 640x480@60Hz는 보통 sync active-low
        h_sync = ~((hcount >= H_SYNC_START) && (hcount < H_SYNC_END));
        v_sync = ~((vcount >= V_SYNC_START) && (vcount < V_SYNC_END));
    end

endmodule

// 임시 데이터
module display_data (
    input logic display_enable,
    input logic [3:0] sw_red,
    input logic [3:0] sw_green,
    input logic [3:0] sw_blue,
    output logic [3:0] red_port,
    output logic [3:0] green_port,
    output logic [3:0] blue_port
);

    always_comb begin
        if (display_enable) begin
            red_port   = sw_red;
            green_port = sw_green;
            blue_port  = sw_blue;
        end else begin
            red_port   = 4'b0;
            green_port = 4'b0;
            blue_port  = 4'b0;
        end
    end

endmodule

module color_print (
    input logic [9:0] x_pixel,
    input logic [9:0] y_pixel,
    input logic display_enable,
    output logic [3:0] red_port,
    output logic [3:0] blue_port,
    output logic [3:0] green_port
);
    always_comb begin
        red_port   = 4'd0;
        blue_port  = 4'd0;
        green_port = 4'd0;
        if (display_enable) begin
            if (y_pixel < 330) begin
                if (x_pixel < 91) begin
                    red_port   = 4'b1110;
                    blue_port  = 4'b1110;
                    green_port = 4'b1110;
                end else if (91 <= x_pixel && x_pixel < 183) begin
                    red_port   = 4'b1111;
                    blue_port  = 4'b0000;
                    green_port = 4'b1111;
                end else if (183 <= x_pixel && x_pixel < 274) begin
                    red_port   = 4'b0000;
                    blue_port  = 4'b1111;
                    green_port = 4'b1111;
                end else if (274 <= x_pixel && x_pixel < 365) begin
                    red_port   = 4'b0000;
                    blue_port  = 4'b0000;
                    green_port = 4'b1111;
                end else if (365 <= x_pixel && x_pixel < 456) begin
                    red_port   = 4'b1111;
                    blue_port  = 4'b1111;
                    green_port = 4'b0000;
                end else if (456 <= x_pixel && x_pixel < 548) begin
                    red_port   = 4'b1111;
                    blue_port  = 4'b0000;
                    green_port = 4'b0000;
                end else if (548 <= x_pixel && x_pixel < 640) begin
                    red_port   = 4'b0000;
                    blue_port  = 4'b0000;
                    green_port = 4'b1111;
                end
            end else if (y_pixel >= 330 && y_pixel < 360) begin
                if (x_pixel < 91) begin
                    red_port   = 4'b0000;
                    blue_port  = 4'b1111;
                    green_port = 4'b0000;
                end else if (91 <= x_pixel && x_pixel < 183) begin
                    red_port   = 4'b0000;
                    blue_port  = 4'b0000;
                    green_port = 4'b0000;
                end else if (183 <= x_pixel && x_pixel < 274) begin
                    red_port   = 4'b1111;
                    blue_port  = 4'b1111;
                    green_port = 4'b0000;
                end else if (274 <= x_pixel && x_pixel < 365) begin
                    red_port   = 4'b0000;
                    blue_port  = 4'b0000;
                    green_port = 4'b0000;
                end else if (365 <= x_pixel && x_pixel < 456) begin
                    red_port   = 4'b0000;
                    blue_port  = 4'b1111;
                    green_port = 4'b1111;
                end else if (456 <= x_pixel && x_pixel < 548) begin
                    red_port   = 4'b0000;
                    blue_port  = 4'b0000;
                    green_port = 4'b0000;
                end else if (548 <= x_pixel && x_pixel < 640) begin
                    red_port   = 4'b1110;
                    blue_port  = 4'b1110;
                    green_port = 4'b1110;
                end
            end else if (y_pixel >= 360 && y_pixel < 480) begin
                if (x_pixel < 106) begin
                    red_port   = 4'b0000;
                    blue_port  = 4'b0000;
                    green_port = 4'b0000;
                end else if (106 <= x_pixel && x_pixel < 212) begin
                    red_port   = 4'b1111;
                    blue_port  = 4'b1111;
                    green_port = 4'b1111;
                end else if (212 <= x_pixel && x_pixel < 318) begin
                    red_port   = 4'b1111;
                    blue_port  = 4'b0000;
                    green_port = 4'b1000;
                end else if (318 <= x_pixel && x_pixel < 424) begin
                    red_port   = 4'b0000;
                    blue_port  = 4'b0000;
                    green_port = 4'b0000;
                end else if (424 <= x_pixel && x_pixel < 530) begin
                    red_port   = 4'b0000;
                    blue_port  = 4'b0000;
                    green_port = 4'b0000;
                end
            end
        end
    end
endmodule
