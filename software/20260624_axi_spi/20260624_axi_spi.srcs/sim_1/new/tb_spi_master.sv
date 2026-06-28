`timescale 1ns / 1ps

module tb_spi_master ();
    parameter C_S00_AXI_DATA_WIDTH = 32;
    parameter C_S00_AXI_ADDR_WIDTH = 5;

    localparam [4:0] ADDR_SPI_CR = 5'h00;
    localparam [4:0] ADDR_SPI_SR = 5'h04;
    localparam [4:0] ADDR_SPI_DR = 5'h08;

    localparam int SR_RX_DONE = 1;
    localparam int SR_TX_BUSY = 3;

    logic                                  spi_sclk;
    logic                                  spi_mosi;
    logic                                  spi_miso;
    logic                                  spi_cs;

    logic                                  s00_axi_aclk;
    logic                                  s00_axi_aresetn;

    logic [    C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr;
    logic [                         2 : 0] s00_axi_awprot;
    logic                                  s00_axi_awvalid;
    logic                                  s00_axi_awready;
    logic [    C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata;
    logic [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb;
    logic                                  s00_axi_wvalid;
    logic                                  s00_axi_wready;
    logic [                         1 : 0] s00_axi_bresp;
    logic                                  s00_axi_bvalid;
    logic                                  s00_axi_bready;
    logic [    C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr;
    logic [                         2 : 0] s00_axi_arprot;
    logic                                  s00_axi_arvalid;
    logic                                  s00_axi_arready;
    logic [    C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata;
    logic [                         1 : 0] s00_axi_rresp;
    logic                                  s00_axi_rvalid;
    logic                                  s00_axi_rready;

    logic [15:0] slave_shift_data;
    logic [15:0] captured_mosi;
    int          captured_count;

    axi_spi_master_v1_0 #(
        .C_S00_AXI_DATA_WIDTH(32),
        .C_S00_AXI_ADDR_WIDTH(5)
    ) dut (
        .spi_sclk(spi_sclk),
        .spi_mosi(spi_mosi),
        .spi_miso(spi_miso),
        .spi_cs  (spi_cs),

        .s00_axi_aclk   (s00_axi_aclk),
        .s00_axi_aresetn(s00_axi_aresetn),

        .s00_axi_awaddr (s00_axi_awaddr),
        .s00_axi_awprot (s00_axi_awprot),
        .s00_axi_awvalid(s00_axi_awvalid),
        .s00_axi_awready(s00_axi_awready),
        .s00_axi_wdata  (s00_axi_wdata),
        .s00_axi_wstrb  (s00_axi_wstrb),
        .s00_axi_wvalid (s00_axi_wvalid),
        .s00_axi_wready (s00_axi_wready),
        .s00_axi_bresp  (s00_axi_bresp),
        .s00_axi_bvalid (s00_axi_bvalid),
        .s00_axi_bready (s00_axi_bready),
        .s00_axi_araddr (s00_axi_araddr),
        .s00_axi_arprot (s00_axi_arprot),
        .s00_axi_arvalid(s00_axi_arvalid),
        .s00_axi_arready(s00_axi_arready),
        .s00_axi_rdata  (s00_axi_rdata),
        .s00_axi_rresp  (s00_axi_rresp),
        .s00_axi_rvalid (s00_axi_rvalid),
        .s00_axi_rready (s00_axi_rready)
    );

    always #5 s00_axi_aclk = ~s00_axi_aclk;

    initial begin
        s00_axi_aclk    = 1'b0;
        s00_axi_aresetn = 1'b0;
        spi_miso        = 1'b0;

        s00_axi_awaddr  = '0;
        s00_axi_awprot  = '0;
        s00_axi_awvalid = 1'b0;
        s00_axi_wdata   = '0;
        s00_axi_wstrb   = '0;
        s00_axi_wvalid  = 1'b0;
        s00_axi_bready  = 1'b0;
        s00_axi_araddr  = '0;
        s00_axi_arprot  = '0;
        s00_axi_arvalid = 1'b0;
        s00_axi_rready  = 1'b0;

        repeat (5) @(posedge s00_axi_aclk);
        s00_axi_aresetn = 1'b1;
        repeat (5) @(posedge s00_axi_aclk);

        run_spi_case("8-bit", 1'b0, 16'h00A5, 16'h003C);
        run_spi_case("16-bit", 1'b1, 16'hBEEF, 16'hCAFE);

        $display("[PASS] 8-bit and 16-bit SPI master tests completed");
        #100;
        $finish;
    end

    task automatic axi_write(input logic [4:0] addr, input logic [31:0] data);
        begin
            @(posedge s00_axi_aclk);
            s00_axi_awaddr  <= addr;
            s00_axi_awvalid <= 1'b1;
            s00_axi_wdata   <= data;
            s00_axi_wstrb   <= 4'hF;
            s00_axi_wvalid  <= 1'b1;
            s00_axi_bready  <= 1'b1;

            wait (s00_axi_awready && s00_axi_wready);
            @(posedge s00_axi_aclk);
            s00_axi_awvalid <= 1'b0;
            s00_axi_wvalid  <= 1'b0;
            s00_axi_awaddr  <= '0;
            s00_axi_wdata   <= '0;
            s00_axi_wstrb   <= '0;

            wait (s00_axi_bvalid);
            @(posedge s00_axi_aclk);
            s00_axi_bready <= 1'b0;
        end
    endtask

    task automatic axi_read(input logic [4:0] addr, output logic [31:0] data);
        begin
            @(posedge s00_axi_aclk);
            s00_axi_araddr  <= addr;
            s00_axi_arvalid <= 1'b1;
            s00_axi_rready  <= 1'b1;

            wait (s00_axi_arready);
            @(posedge s00_axi_aclk);
            s00_axi_arvalid <= 1'b0;
            s00_axi_araddr  <= '0;

            wait (s00_axi_rvalid);
            data = s00_axi_rdata;
            @(posedge s00_axi_aclk);
            s00_axi_rready <= 1'b0;
        end
    endtask

    task automatic wait_done;
        logic [31:0] sr;
        int timeout;
        begin
            timeout = 0;
            do begin
                axi_read(ADDR_SPI_SR, sr);
                timeout++;
                if (timeout > 1000) begin
                    $fatal(1, "[FAIL] Timeout waiting for transfer to start");
                end
            end while (!sr[SR_TX_BUSY] && sr[SR_RX_DONE]);

            timeout = 0;
            do begin
                axi_read(ADDR_SPI_SR, sr);
                timeout++;
                if (timeout > 1000) begin
                    $fatal(1, "[FAIL] Timeout waiting for rx_done");
                end
            end while (!sr[SR_RX_DONE]);

            if (sr[SR_TX_BUSY]) begin
                $fatal(1, "[FAIL] tx_busy remained high when rx_done asserted: SR=0x%08h", sr);
            end
        end
    endtask

    task automatic run_spi_case(
        input string       name,
        input logic        data_frame_16,
        input logic [15:0] master_tx,
        input logic [15:0] slave_tx
    );
        logic [31:0] cr;
        logic [31:0] cr_start;
        logic [31:0] rx_data;
        logic [15:0] expected_mosi;
        logic [15:0] expected_rx;
        int          bit_count;
        begin
            bit_count      = data_frame_16 ? 16 : 8;
            expected_mosi  = data_frame_16 ? master_tx : {8'd0, master_tx[7:0]};
            expected_rx    = data_frame_16 ? slave_tx  : {8'd0, slave_tx[7:0]};
            slave_shift_data = slave_tx;
            captured_mosi    = 16'd0;
            captured_count   = 0;

            // SPI_CR: DFF[7], MSTR[6], start[5], spi_br[4:2], CPOL[1], CPHA[0].
            // spi_br=000 keeps the simulation short. CPOL=0, CPHA=0.
            cr       = {24'd0, data_frame_16, 1'b1, 1'b0, 3'b000, 1'b0, 1'b0};
            cr_start = cr | 32'h0000_0020;

            axi_write(ADDR_SPI_CR, cr);
            axi_write(ADDR_SPI_DR, {16'd0, master_tx});
            axi_write(ADDR_SPI_CR, cr_start);

            wait_done();
            axi_read(ADDR_SPI_DR, rx_data);

            if (rx_data[15:0] !== expected_rx) begin
                $fatal(1, "[FAIL] %s RX mismatch: expected 0x%04h, got 0x%04h",
                       name, expected_rx, rx_data[15:0]);
            end

            if (captured_count != bit_count) begin
                $fatal(1, "[FAIL] %s MOSI bit count mismatch: expected %0d, got %0d",
                       name, bit_count, captured_count);
            end

            if (captured_mosi !== expected_mosi) begin
                $fatal(1, "[FAIL] %s MOSI mismatch: expected 0x%04h, got 0x%04h",
                       name, expected_mosi, captured_mosi);
            end

            $display("[PASS] %s TX=0x%04h RX=0x%04h", name, master_tx, rx_data[15:0]);
            repeat (5) @(posedge s00_axi_aclk);
        end
    endtask

    always @(negedge spi_cs) begin
        spi_miso <= slave_shift_data[(dut.SPI_CR[7]) ? 15 : 7];
    end

    always @(posedge spi_sclk) begin
        if (!spi_cs) begin
            captured_mosi <= {captured_mosi[14:0], spi_mosi};
            captured_count++;
        end
    end

    always @(negedge spi_sclk) begin
        if (!spi_cs) begin
            if (dut.SPI_CR[7]) begin
                slave_shift_data <= {slave_shift_data[14:0], 1'b0};
                spi_miso         <= slave_shift_data[14];
            end else begin
                slave_shift_data <= {8'd0, slave_shift_data[6:0], 1'b0};
                spi_miso         <= slave_shift_data[6];
            end
        end
    end
endmodule
