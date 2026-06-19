`timescale 1ns / 1ps

module axi_ram (
    input logic s_axi_clk,
    input logic s_axi_rst_n,

    input  logic [31:0] s_axi_awaddr,
    input  logic        s_axi_awvalid,
    output logic        s_axi_awready,

    input  logic [31:0] s_axi_wdata,
    input  logic        s_axi_wvalid,
    output logic        s_axi_wready,

    output logic s_axi_bresp,
    input  logic s_axi_bvalid,
    output logic s_axi_bready,

    input  logic [31:0] s_axi_araddr,
    input  logic        s_axi_arvalid,
    output logic        s_axi_arready,

    output logic [31:0] s_axi_rdata,
    output logic        s_axi_rresp,
    output logic        s_axi_rvalid,
    input  logic        s_axi_rready
);
    typedef enum logic [1:0] {
        AW_IDLE,
        AW_VALID,
        AW_BVALID
    } aw_state_t;

    typedef enum logic [1:0] {
        W_IDLE,
        W_VALID,
        W_BVALID
    } w_state_t;

    typedef enum logic [1:0] {
        B_IDLE,
        B_VALID
    } b_state_t;

    state_t state;

    logic [7:0] fifo_waddr;
    logic [7:0] fifo_wdata;

    always_ff @(posedge axi_clk or negedge axi_rst_n) begin
        if(!axi_rst_n) begin
            state <= S0;
        end else begin
            case(state)
                S0 : begin
                    if(s_axi_awvalid) begin
                        fifo_waddr <= s_axi_awaddr[7:0];
                        s_axi_awready <= 1'b1;
                        state <= S1;
                    end
                end
                S1 : begin
                    if(s_axi_rready) begin
                        state <= S0;
                    end
                end
            endcase
        end
    end 


    always_ff @(posedge axi_clk or negedge axi_rst_n) begin
        if(!axi_rst_n) begin
            state <= S0;
        end else begin
            case(state)
                S0 : begin
                    if(s_axi_awvalid) begin
                        fifo_waddr <= s_axi_awaddr[7:0];
                        s_axi_awready <= 1'b1;
                        state <= S1;
                    end
                end
                S1 : begin
                    if(s_axi_wvalid) begin
                        fifo_wdata <= s_axi_wdata[7:0];
                        s_axi_wready <= 1'b1;
                        state <= S2;
                    end
                end
                S2 :  begin
                    if()
                end
            endcase
        end
    end 

    ram u1_ram (
        .clk  (axi_clk),
        .we   (we),
        .raddr(raddr),
        .waddr(waddr),
        .wdata(wdata),
        .rdata(rdata)
    );
endmodule

module ram (
    input logic clk,
    input logic we,
    input logic [7:0] raddr,
    input logic [7:0] waddr,
    input logic [7:0] wdata,
    output logic [7:0] rdata
);
    logic [7:0] ram[0:255];

    always_ff @(posedge clk) begin
        if (we) begin
            ram[waddr] <= wdata;
        end else begin
            rdata <= ram[raddr];
        end
    end
endmodule
