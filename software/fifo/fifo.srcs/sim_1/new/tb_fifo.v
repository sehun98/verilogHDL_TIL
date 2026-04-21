`timescale 1ns / 1ps

// Scenario 1 : empty read try
// Scenario 2 : write
// Scenario 3 : write full try
// Scenario 4 : read
// Scenario 5 : reset
// Scenario 6 : write 1
// Scenario 7 : read write

module tb_fifo;
    reg        clk;
    reg        rst_n;
    reg        w_en;
    reg  [7:0] din;
    reg        r_en;
    wire [7:0] dout;
    wire       empty;
    wire       full;


    fifo u1_fifo (
        .clk  (clk),
        .rst_n(rst_n),
        .w_en (w_en),
        .din  (din),
        .r_en (r_en),
        .dout (dout),
        .empty(empty),
        .full (full)
    );

    wire [7:0] d_w_addr = u1_fifo.w_addr;
    wire [7:0] d_r_addr = u1_fifo.r_addr;

    wire [7:0] d_mem [0:127] = u1_fifo.mem;

    task read_data;
        begin
            @(posedge clk);
            r_en = 1;
            @(posedge clk);
            r_en = 0;
            $strobe("[%f] r_addr : %d, dout : %d", $time, d_r_addr, dout);
        end
    endtask
    
    task write_data;
    input [7:0] t_data;
        begin
            @(posedge clk);
            din = t_data;
            w_en = 1;
            @(posedge clk);
            w_en = 0;
            $strobe("[%f] w_addr : %d, mem : %d", $time, d_w_addr, d_mem[d_w_addr[6:0]-1]);
        end
    endtask

    always #5 clk = ~clk;

    initial begin
        clk   = 0;
        rst_n = 0;
        w_en  = 0;
        r_en  = 0;
        din   = 0;

        repeat (5) @(posedge clk);
        rst_n = 1;

        // Scenario 1 : empty read try
        $strobe("=========================== scenario 1 ===========================");
        read_data();
        
        // Scenario 2 : write
        $strobe("=========================== scenario 2 ===========================");
        write_data(1);

        // Scenario 3 : write full try
        
        $strobe("=========================== scenario 3 ===========================");
        repeat(128) write_data(1);
        write_data(2);

        // Scenario 4 : read
        $strobe("=========================== scenario 4 ===========================");
        read_data();
        write_data(6);
        
        // Scenario 5 : reset
        $strobe("=========================== scenario 5 ===========================");
        rst_n = 0;
        @(negedge clk);
        rst_n = 1;
        $strobe("w_addr : %d, r_addr : %d", d_w_addr, d_r_addr);

        // Scenario 6 : write 1
        $strobe("=========================== scenario 6 ===========================");
        write_data(3);

        // Scenario 7 : read write
        $strobe("=========================== scenario 7 ===========================");
            @(posedge clk);
            r_en = 1;
            din = 10;
            w_en = 1;
            @(posedge clk);
            r_en = 0;
            w_en = 0;
            $strobe("[%f] r_addr : %d, dout : %d", $time, d_r_addr, dout);
            $strobe("[%f] w_addr : %d, mem : %d", $time, d_w_addr, d_mem[d_w_addr[6:0]-1]);


        $finish;
    end

endmodule
