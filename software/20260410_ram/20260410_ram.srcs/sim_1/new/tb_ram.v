`timescale 1ns / 1ps

module tb_ram;
    reg clk;

    reg        we_a;
    reg [7:0]  waddr_a;
    reg [7:0]  wdata_a;
    reg [7:0]  raddr_a;
    wire [7:0] rdata_a;

    reg        we_b;
    reg [7:0]  waddr_b;
    reg [7:0]  wdata_b;
    reg [7:0]  raddr_b;
    wire [7:0] rdata_b;

    ram u1_ram (
        .clk    (clk),

        .we_a   (we_a),
        .waddr_a(waddr_a),
        .wdata_a(wdata_a),
        .raddr_a(raddr_a),
        .rdata_a(rdata_a),

        .we_b   (we_b),
        .waddr_b(waddr_b),
        .wdata_b(wdata_b),
        .raddr_b(raddr_b),
        .rdata_b(rdata_b)
    );

    // clock
    always #5 clk = ~clk;

    initial begin
        // 초기화
        clk     = 0;

        we_a    = 0;
        waddr_a = 0;
        wdata_a = 0;
        raddr_a = 0;

        we_b    = 0;
        waddr_b = 0;
        wdata_b = 0;
        raddr_b = 0;

        // -----------------------------
        // Scenario 1: Port A 단일 write/read
        // -----------------------------
        $display("Scenario 1: Port A single write/read");

        @(posedge clk);
        we_a    <= 1;
        waddr_a <= 8'h05;
        wdata_a <= 8'hAA;
        raddr_a <= 8'h00;

        @(posedge clk);
        we_a    <= 0;
        raddr_a <= 8'h05;

        @(posedge clk);
        $display("Port A Read addr=0x05, rdata=0x%02h (expected=0xAA)", rdata_a);

        // -----------------------------
        // Scenario 2: Port B 단일 write/read
        // -----------------------------
        $display("Scenario 2: Port B single write/read");

        @(posedge clk);
        we_b    <= 1;
        waddr_b <= 8'h10;
        wdata_b <= 8'h55;
        raddr_b <= 8'h00;

        @(posedge clk);
        we_b    <= 0;
        raddr_b <= 8'h10;

        @(posedge clk);
        $display("Port B Read addr=0x10, rdata=0x%02h (expected=0x55)", rdata_b);

        // -----------------------------
        // Scenario 3: Port A write + Port B read 동시 수행
        // -----------------------------
        $display("Scenario 3: Port A write / Port B read simultaneously");

        @(posedge clk);
        we_a    <= 1;
        waddr_a <= 8'h20;
        wdata_a <= 8'h99;

        we_b    <= 0;
        raddr_b <= 8'h05;  // 이전에 A가 저장한 값 읽기

        @(posedge clk);
        we_a    <= 0;
        $display("Port B Read addr=0x05, rdata=0x%02h (expected=0xAA)", rdata_b);

        // -----------------------------
        // Scenario 4: 같은 주소 접근 관찰
        // -----------------------------
        $display("Scenario 4: same address collision observation");

        @(posedge clk);
        we_a    <= 1;
        waddr_a <= 8'h30;
        wdata_a <= 8'hF0;

        we_b    <= 0;
        raddr_b <= 8'h30;

        @(posedge clk);
        we_a    <= 0;
        $display("Collision observation, Port B rdata=0x%02h (device dependent)", rdata_b);

        @(posedge clk);
        raddr_b <= 8'h30;

        @(posedge clk);
        $display("After write, Port B Read addr=0x30, rdata=0x%02h (expected=0xF0)", rdata_b);

        #20;
        $finish;
    end

endmodule