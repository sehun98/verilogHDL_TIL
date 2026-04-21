`timescale 1ns / 1ps

module tb_top_uart_tx_counter;
    reg  clk;
    reg  rst_n;
    reg  btnR;
    reg  [7:0] tx_data;
    wire tx;

    parameter BTN_DELAY = 100_000_000 / 5; // 1s 0.2s 200ms

    top_uart_tx_counter u1_top_uart_tx_counter (
        .clk(clk),
        .rst_n(rst_n),
        .btnR(btnR),
        .tx(tx)
    );

    always #5 clk = ~clk;

    task btn_press;
        begin
            @(negedge clk);
            tx_data = 8'h30;
            btnR = 1;
            #(BTN_DELAY);
            btnR = 0;
        end
    endtask

    initial begin
        clk = 0;
        rst_n = 0;
        repeat(5) @(posedge clk);
        rst_n = 1;

        btn_press();

        #100_000_00;
        $finish();
    end        

endmodule
