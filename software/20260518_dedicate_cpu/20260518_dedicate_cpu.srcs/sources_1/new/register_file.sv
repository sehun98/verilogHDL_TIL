`timescale 1ns / 1ps

module dedicate (
    input  wire       clk,
    input  wire       rst_n,
    output wire [7:0] out
);

    wire       src_sel;
    wire       we;
    wire [1:0] raddr0;
    wire [1:0] raddr1;
    wire [1:0] waddr;
    wire       eq_10;

    dedicate_datapath u_datapath (
        .clk    (clk),
        .src_sel(src_sel),
        .we     (we),
        .raddr0 (raddr0),
        .raddr1 (raddr1),
        .waddr  (waddr),
        .eq_10  (eq_10),
        .out    (out)
    );

    dedicate_control_unit u_control_unit (
        .clk    (clk),
        .rst_n  (rst_n),
        .src_sel(src_sel),
        .we     (we),
        .raddr0 (raddr0),
        .raddr1 (raddr1),
        .waddr  (waddr),
        .eq_10  (eq_10),
        .out    (out)
    );

endmodule
module dedicate_control_unit (
    input  wire       clk,
    input  wire       rst_n,

    output logic      src_sel,
    output logic      we,
    output logic [1:0] raddr0,
    output logic [1:0] raddr1,
    output logic [1:0] waddr,

    input  wire       eq_10,
    input  wire [7:0] out
);

    typedef enum logic [3:0] {
        S0, S1, S2, S3, S4, S5, S6, S7, S8
    } state_t;

    state_t state, n_state;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= S0;
        else
            state <= n_state;
    end

    always_comb begin
        n_state = state;

        case (state)
            S0: n_state = S1;
            S1: n_state = S2;
            S2: n_state = S3;
            S3: n_state = S4;
            S4: begin
                if (eq_10)
                    n_state = S8;
                else
                    n_state = S5;
            end

            S5: n_state = S6;
            S6: n_state = S7;
            S7: n_state = S4;
            S8: n_state = S8;

            default: n_state = S0;
        endcase
    end

    always_comb begin
        src_sel = 1'b0;
        we      = 1'b0;
        raddr0  = 2'd0;
        raddr1  = 2'd0;
        waddr   = 2'd0;

        case (state)
            // R0 = 0
            S0: begin
                src_sel = 1'b1;
                we      = 1'b1;
                waddr   = 2'd0;
            end

            // R1 = 1
            S1: begin
                src_sel = 1'b0;
                we      = 1'b1;
                waddr   = 2'd1;
            end

            // R2 = 0
            S2: begin
                src_sel = 1'b1;
                we      = 1'b1;
                raddr0  = 2'd0;
                raddr1  = 2'd0;
                waddr   = 2'd2;
            end

            // R3 = 0
            S3: begin
                src_sel = 1'b1;
                we      = 1'b1;
                raddr0  = 2'd0;
                raddr1  = 2'd0;
                waddr   = 2'd3;
            end

            // read R3, R2
            S4: begin
                we      = 1'b0;
                raddr0  = 2'd3;
                raddr1  = 2'd2;
            end

            // compare R3
            S5: begin
                we      = 1'b0;
                raddr0  = 2'd3;
                raddr1  = 2'd2;
            end

            // R3 = R3 + R1
            S6: begin
                src_sel = 1'b1;
                we      = 1'b1;
                raddr0  = 2'd3;
                raddr1  = 2'd1;
                waddr   = 2'd3;
            end

            // R2 = R2 + R3
            S7: begin
                src_sel = 1'b1;
                we      = 1'b1;
                raddr0  = 2'd3;
                raddr1  = 2'd2;
                waddr   = 2'd2;
            end

            S8: begin
                we      = 1'b0;
                raddr0  = 2'd3;
                raddr1  = 2'd2;
            end
        endcase
    end

endmodule
module dedicate_datapath (
    input  wire       clk,
    input  wire       src_sel,
    input  wire       we,
    input  wire [1:0] raddr0,
    input  wire [1:0] raddr1,
    input  wire [1:0] waddr,
    output wire       eq_10,
    output wire [7:0] out
);

    wire [7:0] w_alu_out;
    wire [7:0] w_mux_out;
    wire [7:0] w_rdata0;
    wire [7:0] w_rdata1;

    mux u1_mux (
        .in0(8'd1),
        .in1(w_alu_out),
        .sel(src_sel),
        .mux_out(w_mux_out)
    );

    register_file #(
        .DEPTH(4)
    ) u2_register_file (
        .clk(clk),
        .we(we),
        .wdata(w_mux_out),
        .waddr(waddr),
        .raddr0(raddr0),
        .raddr1(raddr1),
        .rdata0(w_rdata0),
        .rdata1(w_rdata1)
    );

    ALU u3_ALU (
        .a(w_rdata0),
        .b(w_rdata1),
        .alu_out(w_alu_out)
    );

    comparator u4_comparator (
        .din(w_rdata0),
        .compare(8'd9),
        .dout(eq_10)
    );

    assign out = w_rdata1;
endmodule

module register_file #(
    parameter DEPTH = 4,
    localparam ADDR_WIDTH = $clog2(DEPTH)
) (
    input  wire                  clk,
    input  wire                  we,
    input       [           7:0] wdata,
    input       [ADDR_WIDTH-1:0] waddr,
    input       [ADDR_WIDTH-1:0] raddr0,
    input       [ADDR_WIDTH-1:0] raddr1,
    output      [           7:0] rdata0,
    output      [           7:0] rdata1
);
    reg [7:0] mem[0:DEPTH-1];

    // R0은 항상 0
    assign rdata0 = (raddr0 == 0) ? 8'd0 : mem[raddr0];
    assign rdata1 = (raddr1 == 0) ? 8'd0 : mem[raddr1];

    always_ff @(posedge clk) begin
        if (we) begin
            mem[waddr] <= wdata;
        end
    end
endmodule

module ALU (
    input  wire [7:0] a,
    input  wire [7:0] b,
    output wire [7:0] alu_out
);
    reg [7:0] out_reg;

    assign alu_out = out_reg;

    always_comb begin
        out_reg = a + b;
    end
endmodule

module mux (
    input wire [7:0] in0,
    input wire [7:0] in1,
    input wire sel,
    output wire [7:0] mux_out
);
    reg [7:0] mux_out_reg;
    assign mux_out = mux_out_reg;

    always_comb begin
        case (sel)
            1'b0: mux_out_reg = in0;
            1'b1: mux_out_reg = in1;
            default: mux_out_reg = in0;
        endcase
    end
endmodule

module comparator (
    input  wire [7:0] din,
    input  wire [7:0] compare,
    output wire dout
);

    assign dout = (din > compare) ? 1'b1 : 1'd0;
endmodule
