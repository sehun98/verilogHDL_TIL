`timescale 1ns / 1ps

module tb_axi ();
    logic        ACLK;
    logic        ARESETn;

    logic [31:0] AWADDR;
    logic        AWVALID;
    logic        AWREADY;
    logic [31:0] WDATA;
    logic        WVALID;
    logic        WREADY;
    logic [ 1:0] BRESP;
    logic        BVALID;
    logic        BREADY;
    logic [31:0] ARADDR;
    logic        ARVALID;
    logic        ARREADY;
    logic [31:0] RDATA;
    logic        RVALID;
    logic        RREADY;
    logic [ 1:0] RRESP;

    logic        transfer;
    logic        ready;
    logic [31:0] addr;
    logic [31:0] wdata;
    logic [31:0] rdata;
    logic        write;

    axi_master u_axi_master (
        .ACLK(ACLK),
        .ARESETn(ARESETn),
        .AWADDR(AWADDR),
        .AWVALID(AWVALID),
        .AWREADY(AWREADY),
        .WDATA(WDATA),
        .WVALID(WVALID),
        .WREADY(WREADY),
        .BRESP(BRESP),
        .BVALID(BVALID),
        .BREADY(BREADY),
        .ARADDR(ARADDR),
        .ARVALID(ARVALID),
        .ARREADY(ARREADY),
        .RDATA(RDATA),
        .RVALID(RVALID),
        .RREADY(RREADY),
        .RRESP(RRESP),
        .transfer(transfer),
        .ready(ready),
        .addr(addr),
        .wdata(wdata),
        .rdata(rdata),
        .write(write)
    );

    axi_slave u_axi_slave (
        .ACLK(ACLK),
        .ARESETn(ARESETn),
        .AWADDR(AWADDR),
        .AWVALID(AWVALID),
        .AWREADY(AWREADY),
        .WDATA(WDATA),
        .WVALID(WVALID),
        .WREADY(WREADY),
        .BRESP(BRESP),
        .BVALID(BVALID),
        .BREADY(BREADY),
        .ARADDR(ARADDR),
        .ARVALID(ARVALID),
        .ARREADY(ARREADY),
        .RDATA(RDATA),
        .RVALID(RVALID),
        .RREADY(RREADY),
        .RRESP(RRESP)
    );

    task axi_write(input logic [31:0] _addr, input logic [31:0] _data);

        wdata = _data;
        addr = _addr;
        write = 1'b1;
        transfer = 1'b1;
        @(posedge ACLK);
        transfer = 1'b0;
        write = 1'b0;
        wait (ready);

        @(posedge ACLK);

        $display("[%0t] AXI WRITE Addr = %0h, WDATA = %0h", $time, addr, wdata);

    endtask

    task axi_read(input logic [31:0] _addr);

        addr = _addr;
        write = 1'b0;
        transfer = 1'b1;
        @(posedge ACLK);
        transfer = 1'b0;
        write = 1'b0;
        wait (ready);

        @(posedge ACLK);

        $display("[%0t] AXI READ Addr = %0h, RDATA = %0h", $time, addr, rdata);
    endtask

    always #5 ACLK = ~ACLK;
    initial begin
        ACLK = 0;
        ARESETn = 0;

        transfer = 1'b0;
        addr = 32'd0;
        wdata = 32'd0;
        write = 1'b0;

        repeat (2) @(posedge ACLK);
        ARESETn = 1;

        axi_write(32'h00, 32'h1111_1111);
        axi_write(32'h04, 32'h2222_2222);
        axi_write(32'h08, 32'h3333_3333);
        axi_write(32'h0C, 32'h4444_4444);


        axi_read(32'h00);
        axi_read(32'h04);
        axi_read(32'h08);
        axi_read(32'h0C);


        #100;
        $finish();
    end
endmodule
