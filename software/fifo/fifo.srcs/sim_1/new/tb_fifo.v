`timescale 1ns / 1ps

// Scenario 1 : empty read try
// Scenario 2 : write
// Scenario 3 : write full try
// Scenario 4 : read
// Scenario 5 : reset
// Scenario 6 : read write

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

    task read_data;
        begin
            @(posedge clk);
            r_en = 1;
            @(posedge clk);
            r_en = 0;
        end
    endtask

    task write_data;
        input [7:0] t_data;
        begin
            @(posedge clk);
            din  = t_data;
            w_en = 1;
            @(posedge clk);
            w_en = 0;
        end
    endtask

    task read_write_data;
        input [7:0] t_data;
        begin
            @(posedge clk);
            din  = t_data;
            w_en = 1;
            r_en = 1;

            @(posedge clk);
            w_en = 0;
            r_en = 0;
        end
    endtask

    always #5 clk = ~clk;

    integer i;

    initial begin
        clk   = 0;
        rst_n = 0;
        w_en  = 0;
        r_en  = 0;
        din   = 0;

        repeat (5) @(posedge clk);
        rst_n = 1;

        // Scenario 1 : empty read try
        read_data();

        // Scenario 2 : read & write try empty
        read_write_data(8'd1);

        // Scenario 3 : write
        write_data(1);

        // Scenario 4 : write full try
        for(i=0;i<128;i=i+1) begin
            write_data(i);
        end

        // Scenario 5 : read
        read_data();
        write_data(6);

        // Scenario 6 : read & write try full
        read_write_data(8'd1);
        #10;

        // Scenario 7 : reset
        rst_n = 0;
        @(negedge clk);
        rst_n = 1;

        // Scenario 8 : read write
        read_data();

        #10;
        $finish;
    end

endmodule
