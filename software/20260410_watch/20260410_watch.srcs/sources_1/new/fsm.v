`timescale 1ns / 1ps

module fsm (
    input wire clk,
    input wire rst_n,
    input wire sw,
    output wire [1:0] led
    );

    localparam IDLE = 1'b0;
    localparam RUN = 1'b1;

    reg state, n_state;

    // 1. state register
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            state <= IDLE;
        end else begin
            state <= n_state;
        end
    end

    // 2. next state logic
    always @(*) begin
        n_state = state;
        case(state)
            IDLE : if(sw) n_state = RUN;
            RUN : if(!sw) n_state = IDLE;
            default : n_state = IDLE;
        endcase
    end

    // 3. datapath
    assign led[0] = (state==RUN);
    assign led[1] = (state==IDLE);

endmodule

module fsm2 (
    input wire clk,
    input wire rst_n,
    input wire [1:0] sw,
    output wire [2:0] led
    );

    localparam LED1 = 2'b00;
    localparam LED2 = 2'b01;
    localparam LED3 = 2'b10;

    reg [1:0] state, n_state;

    // 1. state register
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            state <= LED1;
        end else begin
            state <= n_state;
        end
    end

    // 2. next state logic
    always @(*) begin
        n_state = state;
        case(state)
            LED1 : if(sw==2'b01) n_state = LED2;
            LED2 : if(sw==2'b10) n_state = LED3;
            LED3 : if(sw==2'b11) n_state = LED1;
            default : n_state = LED1;
        endcase
    end

    // 3. datapath
    assign led[0] = (state==LED1);
    assign led[1] = (state==LED2);
    assign led[2] = (state==LED3);
endmodule



module fsm3 (
    input wire clk,
    input wire rst_n,
    input wire [2:0] sw,
    output wire [2:0] led
    );

    localparam A = 3'b000;
    localparam B = 3'b001;
    localparam C = 3'b010;
    localparam D = 3'b011;
    localparam E = 3'b100;

    reg [2:0] state, n_state;

    // 1. state register
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            state <= A;
        end else begin
            state <= n_state;
        end
    end

    // 2. next state logic
    always @(*) begin
        n_state = state;
        case(state)
            A : begin 
                if(sw==3'b001) n_state = B;
                else if(sw==3'b010) n_state = C;
            end
            B : if(sw==3'b010) n_state = C;
            C : if(sw==3'b100) n_state = D;
            D : begin
                if(sw==3'b111) n_state = E;
                else if(sw==3'b000) n_state = A;
                else if(sw==3'b001) n_state = B;
            end
            E : if(sw==3'b000) n_state = A;
            default : n_state = A;
        endcase
    end

    // 3. datapath
    assign led[0] = (state==B) || (state==E);
    assign led[1] = (state==C) || (state==E);
    assign led[2] = (state==D) || (state==E);
endmodule

