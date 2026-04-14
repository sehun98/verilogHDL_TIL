`timescale 1ns / 1ps

module tb_fsm;
    reg  clk;
    reg  rst_n;
    reg  din;
    wire dout;

    task send_bit;
        input bit_val;
        begin
            @(negedge clk);  // 미리 세팅
            din = bit_val;
            @(posedge clk);  // 여기서 샘플링됨
        end
    endtask

    // 1 0 1 0 1 0 0 0 1 0 1 0 1 1 1 1 0 1 0 0 1 0 1 0
    initial begin
        // 시나리오 1: 1010 SUCCESS CASE 
        send_bit(1);
        send_bit(0);
        send_bit(1);
        send_bit(0);

        send_bit(1);
        send_bit(0);
        send_bit();
        send_bit();
        send_bit();
        send_bit();
        send_bit();
        send_bit();
        send_bit();
        send_bit();
        send_bit();
        send_bit();
        send_bit();
        send_bit();
        send_bit();
        send_bit();
        send_bit();
        send_bit();

        // 시나리오 2: 1010 SUCCESS CASE 

    end

endmodule
