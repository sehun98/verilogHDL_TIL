`timescale 1ns / 1ps

module moore (
    input wire clk,
    input wire rst_n,
    input wire din,
    output reg dout
    );
    // 00 01 10 11
    localparam [2:0] A = 'b000;
    localparam [2:0] B = 'b001;
    localparam [2:0] C = 'b010;
    localparam [2:0] D = 'b011;
    localparam [2:0] E = 'b100;

    reg [2:0] state, n_state;

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
                else n_state = E;
            E : if(din) n_state = B;
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
            D : dout = 1'b0;
            E : dout = 1'b1;
            default: dout = 1'b0;
        endcase
    end 

endmodule
