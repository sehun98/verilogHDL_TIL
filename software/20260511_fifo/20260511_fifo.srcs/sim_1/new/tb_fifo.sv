`timescale 1ns / 1ps

module tb_fifo ();
    logic clk;
    logic rst_n;
    
    logic [7:0] push_data;
    logic push;
    logic pop;
    
    logic [7:0] pop_data;
    logic full;
    logic empty;

    fifo dut (
        .clk(clk),
        .rst_n(rst_n),
        .push_data(push_data),
        .pop_data(pop_data),
        .push(push),
        .pop(pop),
        .full(full),
        .empty(empty)
    );

    always #5 clk = ~clk;

    localparam DEPTH = 4;
    localparam DEBUG_DELAY = 100;
    integer i;

    initial begin
        clk = 0;
        rst_n = 0;
        push_data = 0;
        push = 0;
        pop = 0;
        repeat (5) @(posedge clk);
        rst_n = 1;

        @(posedge clk) #1;
        // push only to occurupt
        for (i = 0; i < DEPTH + 1; i = i + 1) begin
            push = 1;
            push_data = i;
            #10;
        end
        push = 0;

        #(DEBUG_DELAY);

        // pop
        for (i = 0; i < DEPTH + 1; i = i + 1) begin
            pop = 1;
            #10;
        end
        pop = 0;

        #(DEBUG_DELAY);
        push = 1;
        push_data = 8'h30;
        #10;

        // push & pop
        for (i = 0; i < DEPTH + 1; i = i + 1) begin
            pop = 1;
            push = 1;
            push_data = i + 8'h30;
            #10;
        end
        pop  = 0;

        push = 0;
        pop  = 0;
        #(DEBUG_DELAY);

        // clear fifo before random test
        pop  = 1;
        push = 0;
        #20;
        pop  = 0;
        push = 0;
        #20;

        #(DEBUG_DELAY);
        $finish;
    end
endmodule
