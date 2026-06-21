`timescale 1ns / 1ps

`define AXI_FND_S00_AXI_FND_CR_OFFSET 0
`define AXI_FND_S00_AXI_FND_DR_OFFSET 4
`define AXI_FND_S00_AXI_FND_BR_OFFSET 8
`define AXI_FND_S00_AXI_SLV_REG3_OFFSET 12

module tb_axi_fnd ();
    localparam C_S00_AXI_DATA_WIDTH = 32;
    localparam C_S00_AXI_ADDR_WIDTH = 4;

    logic [3:0] digit;
    logic [7:0] seg;

    logic s00_axi_aclk;
    logic s00_axi_aresetn;
    logic [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr;
    logic [2 : 0] s00_axi_awprot;
    logic s00_axi_awvalid;
    logic s00_axi_awready;
    logic [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata;
    logic [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb;
    logic s00_axi_wvalid;
    logic s00_axi_wready;
    logic [1 : 0] s00_axi_bresp;
    logic s00_axi_bvalid;
    logic s00_axi_bready;
    logic [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr;
    logic [2 : 0] s00_axi_arprot;
    logic s00_axi_arvalid;
    logic s00_axi_arready;
    logic [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata;
    logic [1 : 0] s00_axi_rresp;
    logic s00_axi_rvalid;
    logic s00_axi_rready;

    axi_fnd_v1_0 #(
        .C_S00_AXI_DATA_WIDTH(32),
        .C_S00_AXI_ADDR_WIDTH(4)
    ) dut (
        .digit(digit),
        .seg(seg),
        .s00_axi_aclk(s00_axi_aclk),
        .s00_axi_aresetn(s00_axi_aresetn),
        .s00_axi_awaddr(s00_axi_awaddr),
        .s00_axi_awprot(s00_axi_awprot),
        .s00_axi_awvalid(s00_axi_awvalid),
        .s00_axi_awready(s00_axi_awready),
        .s00_axi_wdata(s00_axi_wdata),
        .s00_axi_wstrb(s00_axi_wstrb),
        .s00_axi_wvalid(s00_axi_wvalid),
        .s00_axi_wready(s00_axi_wready),
        .s00_axi_bresp(s00_axi_bresp),
        .s00_axi_bvalid(s00_axi_bvalid),
        .s00_axi_bready(s00_axi_bready),
        .s00_axi_araddr(s00_axi_araddr),
        .s00_axi_arprot(s00_axi_arprot),
        .s00_axi_arvalid(s00_axi_arvalid),
        .s00_axi_arready(s00_axi_arready),
        .s00_axi_rdata(s00_axi_rdata),
        .s00_axi_rresp(s00_axi_rresp),
        .s00_axi_rvalid(s00_axi_rvalid),
        .s00_axi_rready(s00_axi_rready)
    );

    always #5 s00_axi_aclk = ~s00_axi_aclk;

    integer i;

    task automatic AXI_FND_mWriteReg(
        input logic [C_S00_AXI_ADDR_WIDTH-1:0] _addr, input logic [31:0] _data);
        begin
            @(posedge s00_axi_aclk);

            s00_axi_awaddr  <= _addr;
            s00_axi_awprot  <= 3'd0;
            s00_axi_awvalid <= 1'b1;

            s00_axi_wdata   <= _data;
            s00_axi_wstrb   <= 4'b1111;
            s00_axi_wvalid  <= 1'b1;

            s00_axi_bready  <= 1'b1;

            // address/data handshake 대기
            wait (s00_axi_awready && s00_axi_wready);
            @(posedge s00_axi_aclk);

            s00_axi_awvalid <= 1'b0;
            s00_axi_wvalid  <= 1'b0;

            // write response 대기
            wait (s00_axi_bvalid);
            @(posedge s00_axi_aclk);

            s00_axi_bready <= 1'b0;

            @(posedge s00_axi_aclk);
        end
    endtask

    initial begin
        s00_axi_aclk = 0;
        s00_axi_aresetn = 0;

        s00_axi_awaddr = 0;
        s00_axi_awprot = 0;
        s00_axi_awvalid = 0;

        s00_axi_wdata = 0;
        s00_axi_wstrb = 0;
        s00_axi_wvalid = 0;

        s00_axi_bready = 0;

        s00_axi_araddr = 0;
        s00_axi_arprot = 0;
        s00_axi_arvalid = 0;

        s00_axi_rready = 0;
        repeat (2) @(posedge s00_axi_aclk);
        s00_axi_aresetn = 1;

        AXI_FND_mWriteReg(`AXI_FND_S00_AXI_FND_BR_OFFSET, 32'd1000);
        AXI_FND_mWriteReg(`AXI_FND_S00_AXI_FND_CR_OFFSET, 32'd1);

        for (i = 0; i < 10000; i = i + 1) begin
            AXI_FND_mWriteReg(`AXI_FND_S00_AXI_FND_DR_OFFSET, i);
            #100_000_000;
        end
    end

endmodule
