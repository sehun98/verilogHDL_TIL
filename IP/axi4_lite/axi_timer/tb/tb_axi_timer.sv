`timescale 1ns / 1ps

`define AXI_TIMER_S00_AXI_TIM_CR_OFFSET 0
`define AXI_TIMER_S00_AXI_TIM_ISR_OFFSET 4
`define AXI_TIMER_S00_AXI_TIM_IER_OFFSET 8
`define AXI_TIMER_S00_AXI_TIM_ICR_OFFSET 12
`define AXI_TIMER_S00_AXI_TIM_CNT_OFFSET 16
`define AXI_TIMER_S00_AXI_TIM_PSC_OFFSET 20
`define AXI_TIMER_S00_AXI_TIM_ARR_OFFSET 24
`define AXI_TIMER_S00_AXI_TIM_CCR_OFFSET 28

module tb_axi_timer ();
    localparam C_S00_AXI_DATA_WIDTH = 32;
    localparam C_S00_AXI_ADDR_WIDTH = 5;

    logic pwm_out;
    logic irq;

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

    always #5 s00_axi_aclk = ~s00_axi_aclk;

    task automatic AXI_TIMER_mWriteReg(
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

            // AW, W handshake 대기
            wait (s00_axi_awready && s00_axi_wready);
            @(posedge s00_axi_aclk);

            s00_axi_awvalid <= 1'b0;
            s00_axi_wvalid  <= 1'b0;

            // B response 대기
            wait (s00_axi_bvalid);
            @(posedge s00_axi_aclk);

            s00_axi_bready <= 1'b0;
        end
    endtask

    task automatic AXI_TIMER_mReadReg(
        input logic [C_S00_AXI_ADDR_WIDTH-1:0] _addr,
        output logic [31:0] _data);
        begin
            @(posedge s00_axi_aclk);

            s00_axi_araddr  <= _addr;
            s00_axi_arprot  <= 3'd0;
            s00_axi_arvalid <= 1'b1;
            s00_axi_rready  <= 1'b1;

            // AR handshake 대기
            wait (s00_axi_arready);
            @(posedge s00_axi_aclk);

            s00_axi_arvalid <= 1'b0;

            // R valid 대기
            wait (s00_axi_rvalid);
            _data = s00_axi_rdata;

            @(posedge s00_axi_aclk);
            s00_axi_rready <= 1'b0;
        end
    endtask

/*
 * 일반 동작 시나리오
 * 1. PSC = 10 -> 100MHz -> 10MHz
 * 2. ARR = 1000 -> 10MHz -> 10KHz
 * 3. CCR = 50 -> 10KHz -> 5KHz
 * 
 * 4. Up Count CEN
 * 5. PWMEN
 * 6. OPM
 * 7. DIR
 */
    initial begin
        logic [31:0] rdata;

        s00_axi_aclk    = 0;
        s00_axi_aresetn = 0;

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

        // --------------------------------------------------
        // Timer Register Setting
        // --------------------------------------------------

        // Prescaler 설정
        // psc_tick 주기 = TIM_PSC + 1 clock
        AXI_TIMER_mWriteReg(`AXI_TIMER_S00_AXI_TIM_PSC_OFFSET, 32'd10);

        // Auto Reload 설정
        // CNT가 ARR까지 카운트 후 update event 발생
        AXI_TIMER_mWriteReg(`AXI_TIMER_S00_AXI_TIM_ARR_OFFSET, 32'd100);

        // Compare 설정
        // CCR=50이면 CNT < CCR 기준 약 50% duty
        AXI_TIMER_mWriteReg(`AXI_TIMER_S00_AXI_TIM_CCR_OFFSET, 32'd20);

        // Interrupt enable
        // bit[0]을 update interrupt enable
        AXI_TIMER_mWriteReg(`AXI_TIMER_S00_AXI_TIM_IER_OFFSET, 32'b1);

        // Timer enable
        // TIM_CR[0] = CEN , TIM_CR[3] = PWMEN
        AXI_TIMER_mWriteReg(`AXI_TIMER_S00_AXI_TIM_CR_OFFSET, (32'b1 | 32'd8));

        #1000_000; // 1ms

        // CNT 읽기
        AXI_TIMER_mReadReg(`AXI_TIMER_S00_AXI_TIM_CNT_OFFSET, rdata);
        $display("TIM_CNT = %0d", rdata);

        // ISR 읽기
        AXI_TIMER_mReadReg(`AXI_TIMER_S00_AXI_TIM_ISR_OFFSET, rdata);
        $display("TIM_ISR = %h", rdata);

        // interrupt flag clear
        // TIM_ICR[0] = update interrupt clear
        AXI_TIMER_mWriteReg(`AXI_TIMER_S00_AXI_TIM_ICR_OFFSET, 32'b1);

        // TIM_CR[0] = CEN , TIM_CR[3] = PWMEN, TIM_CR[1] = OPM, TIM_CR[2] = DIR
        AXI_TIMER_mWriteReg(`AXI_TIMER_S00_AXI_TIM_CR_OFFSET, (32'b1 | 32'd8 | 32'd4));

        #1000_000; // 1ms

        $finish;
    end

    axi_timer_v1_0 #(
        .C_S00_AXI_DATA_WIDTH(32),
        .C_S00_AXI_ADDR_WIDTH(5)
    ) dut (
        .pwm_out        (pwm_out),
        .irq            (irq),
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
endmodule


