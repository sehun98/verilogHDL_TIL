`timescale 1ns / 1ps

module tb_register_file_latency_compare;
    parameter REG_SIZE = 4;
    localparam ADDR_SIZE = $clog2(REG_SIZE);

    reg                  clk;
    reg  [          7:0] w_data;
    wire [          7:0] r_data_no_latency;
    wire [          7:0] r_data_1_latency;
    reg  [ADDR_SIZE-1:0] w_addr;
    reg  [ADDR_SIZE-1:0] r_addr;
    reg                  w_en;
    reg                  r_en;

    register_file_no_latency #(
        .REG_SIZE(REG_SIZE)
    ) u_no_latency (
        .clk(clk),
        .w_data(w_data),
        .r_data(r_data_no_latency),
        .w_addr(w_addr),
        .r_addr(r_addr),
        .w_en(w_en)
    );

    register_file_1_latency #(
        .REG_SIZE(REG_SIZE)
    ) u_1_latency (
        .clk(clk),
        .w_data(w_data),
        .r_data(r_data_1_latency),
        .w_addr(w_addr),
        .r_addr(r_addr),
        .w_en(w_en),
        .r_en(r_en)
    );

    always #5 clk = ~clk;

    task write_data;
        input [ADDR_SIZE-1:0] addr;
        input [7:0] data;
        begin
            @(negedge clk);
            w_addr = addr;
            w_data = data;
            w_en   = 1;

            @(negedge clk);
            w_en   = 0;

            $display("[%0t] WRITE addr=%0d, data=%h", $time, addr, data);
        end
    endtask

    task read_data;
        input [ADDR_SIZE-1:0] addr;
        begin
            @(negedge clk);
            r_addr = addr;
            r_en   = 1;

            $display("[%0t] READ REQUEST addr=%0d", $time, addr);

            @(posedge clk);
            $strobe("[%0t] after posedge | r_addr=%0d | no_latency=%h | 1_latency=%h",
                    $time, r_addr, r_data_no_latency, r_data_1_latency);

            @(negedge clk);
            r_en = 0;
        end
    endtask

    task change_addr_without_ren;
        input [ADDR_SIZE-1:0] addr;
        begin
            @(negedge clk);
            r_en   = 0;
            r_addr = addr;

            #1;
            $display("[%0t] ADDR CHANGE without r_en | r_addr=%0d | no_latency=%h | 1_latency=%h",
                     $time, r_addr, r_data_no_latency, r_data_1_latency);
        end
    endtask

    initial begin
        clk    = 0;
        w_data = 0;
        w_addr = 0;
        r_addr = 0;
        w_en   = 0;
        r_en   = 0;

        repeat (5) @(posedge clk);

        $display("================ WRITE DATA ================");
        write_data(2'd0, 8'h0A);
        write_data(2'd1, 8'h0B);
        write_data(2'd2, 8'h0C);
        write_data(2'd3, 8'h0D);

        $display("================ READ WITH r_en ================");
        read_data(2'd0);
        read_data(2'd1);
        read_data(2'd2);
        read_data(2'd3);

        $display("================ ADDRESS CHANGE WITHOUT r_en ================");
        change_addr_without_ren(2'd0);
        change_addr_without_ren(2'd1);
        change_addr_without_ren(2'd2);
        change_addr_without_ren(2'd3);

        #20;
        $finish;
    end

endmodule