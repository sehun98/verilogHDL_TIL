`timescale 1ns / 1ps

module tb_fifo;
    reg        clk;
    reg        reset;
    reg  [7:0] push_data;
    reg        push;
    reg        pop;
    wire [7:0] pop_data;
    wire       full;
    wire       empty;

    localparam DEPTH = 4;
    localparam DEBUG_DELAY = 100;

    // random verification
    reg [7:0] compare_data[0:DEPTH-1];
    reg [1:0] push_cnt, pop_cnt;

    fifo #(
        .DEPTH(DEPTH)
    ) u1_fifo (
        .clk(clk),
        .reset(reset),
        .push_data(push_data),
        .push(push),
        .pop(pop),
        .pop_data(pop_data),
        .full(full),
        .empty(empty)
    );

    always #5 clk = ~clk;

    integer i;

    initial begin
        clk = 0;
        reset = 0;
        push_data = 0;
        push = 0;
        pop = 0;
        repeat (5) @(posedge clk);
        reset = 1;

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

        // random : push data, push, pop
        push_cnt = 0;
        pop_cnt  = 0;

        @(posedge clk);
        for (i = 0; i < 16; i = i + 1) begin
            #1;

            pop = $random % 2;
            push = $random % 2;
            push_data = $random % 256;
            // compare_data
            if (push && !full) begin
                compare_data[push_cnt] = push_data;
                push_cnt = push_cnt + 1;
            end
            @(negedge clk);
            if (!empty && pop) begin
                if (pop_data == compare_data[pop_cnt]) begin
                    $display("[%f] pass : pop_data = %h, compare_data = %h",
                             $time, pop_data, compare_data[pop_cnt]);
                end else begin
                    $display("[%f] fail : pop_data = %h, compare_data = %h",
                             $time, pop_data, compare_data[pop_cnt]);
                end
                pop_cnt = pop_cnt + 1;
            end
            @(posedge clk);
        end

        #(DEBUG_DELAY);
        $finish;
    end

endmodule

// full empty도 작업
