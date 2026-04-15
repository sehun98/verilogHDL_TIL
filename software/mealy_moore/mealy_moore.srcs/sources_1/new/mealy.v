`timescale 1ns / 1ps

module mealy (
    input wire clk,
    input wire rst_n,
    input wire din,
    output reg dout
    );
    // 00 01 10 11
    localparam [1:0] A = 2'b00;
    localparam [1:0] B = 2'b01;
    localparam [1:0] C = 2'b10;
    localparam [1:0] D = 2'b11;

    reg [1:0] state, n_state;

    // 1. state register
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            state <= A;
        end else begin
            state <= n_state;
        end
    end

    // 2. next state combinational logic
    always @(*) begin
        n_state = state;
        case (state)
            A : if(din) n_state = B;
                else n_state = A;
            B : if(!din) n_state = C;
                else n_state = B;
            C : if(!din) n_state = A;
                else n_state = D;
            D : if(din) n_state = B;
                else n_state = A;
            default: n_state = A;
        endcase
    end 

    // 3. output combinational logic
    always @(*) begin
        dout = 1'b0;
        case (state)
            A : dout = 1'b0;
            B : dout = 1'b0;
            C : dout = 1'b0;
            D : if(!din) dout = 1'b1;
                else dout = 1'b0;
            default: dout = 1'b0;
        endcase
    end 

endmodule
