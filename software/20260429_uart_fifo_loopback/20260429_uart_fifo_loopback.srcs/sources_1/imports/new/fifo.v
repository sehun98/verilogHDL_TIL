`timescale 1ns / 1ps

module fifo #(
    parameter  DEPTH     = 4,
    localparam BIT_WIDTH = $clog2(DEPTH)
) (
    input  wire       clk,
    input  wire       reset,
    input  wire [7:0] push_data,
    input  wire       push,
    input  wire       pop,
    output wire [7:0] pop_data,
    output wire       full,
    output wire       empty
);

    wire [BIT_WIDTH-1:0] w_waddr;
    wire [BIT_WIDTH-1:0] w_raddr;

    register_file #(
        .DEPTH(DEPTH)
    ) u1_register_file (
        .clk(clk),
        .waddr(w_waddr),
        .raddr(w_raddr),
        .wdata(push_data),
        .rdata(pop_data),
        .we   ((~full) & push)
    );

    control_unit #(
        .DEPTH(DEPTH)
    ) u2_control_unit (
        .clk  (clk),
        .reset(reset),
        .push (push),
        .pop  (pop),
        .wptr (w_waddr),
        .rptr (w_raddr),
        .full (full),
        .empty(empty)
    );

endmodule

module register_file #(
    parameter  DEPTH     = 4,
    localparam BIT_WIDTH = $clog2(DEPTH)
) (
    input wire                 clk,
    input wire [BIT_WIDTH-1:0] waddr,
    input wire [BIT_WIDTH-1:0] raddr,
    input wire [          7:0] wdata,
    input wire [          7:0] rdata,
    input wire                 we
);
    // 2**BIT_WIDTH -1 
    reg [7:0] register_file[0:DEPTH-1];

    always @(posedge clk) begin
        if (we) begin
            register_file[waddr] <= wdata;
        end
    end

    assign rdata = register_file[raddr];

endmodule

module control_unit #(
    parameter  DEPTH     = 4,
    localparam BIT_WIDTH = $clog2(DEPTH)
) (
    input  wire                 clk,
    input  wire                 reset,
    input  wire                 push,
    input  wire                 pop,
    output wire [BIT_WIDTH-1:0] wptr,
    output wire [BIT_WIDTH-1:0] rptr,
    output wire                 full,
    output wire                 empty
);
    reg [BIT_WIDTH-1:0] wptr_reg, wptr_next;
    reg [BIT_WIDTH-1:0] rptr_reg, rptr_next;

    reg full_reg, full_next;
    reg empty_reg, empty_next;

    always @(posedge clk or negedge reset) begin
        if (!reset) begin
            wptr_reg  <= 0;
            rptr_reg  <= 0;
            full_reg  <= 0;
            empty_reg <= 1;
        end else begin
            wptr_reg  <= wptr_next;
            rptr_reg  <= rptr_next;
            full_reg  <= full_next;
            empty_reg <= empty_next;
        end
    end

    always @(*) begin
        wptr_next  = wptr_reg;
        rptr_next  = rptr_reg;
        full_next  = full_reg;
        empty_next = empty_reg;
        case ({
            push, pop
        })
            // 초기상태 2'b00
            // push
            2'b10:
            if (!full_reg) begin
                wptr_next  = wptr_reg + 1;
                empty_next = 0;
                if (wptr_next == rptr_reg) begin
                    full_next = 1;
                end
            end
            // pop
            2'b01:
            if (!empty_reg) begin
                rptr_next = rptr_reg + 1;
                full_next = 0;
                if (rptr_next == wptr_reg) begin
                    empty_next = 1;
                end
            end
            // 우선순위 full > empty > 
            2'b11: begin
                if (full_reg) begin
                    rptr_next = rptr_reg + 1;
                    full_next = 0;
                end else if (empty_reg) begin
                    wptr_next  = wptr_reg + 1;
                    empty_next = 0;
                end else begin
                    wptr_next = wptr_reg + 1;
                    rptr_next = rptr_reg + 1;
                end
            end
        endcase
    end

    assign wptr  = wptr_reg;
    assign rptr  = rptr_reg;
    assign full  = full_reg;
    assign empty = empty_reg;
endmodule

