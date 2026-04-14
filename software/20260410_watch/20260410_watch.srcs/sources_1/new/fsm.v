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

module fsm4 (
    input wire clk,
    input wire rst_n,
    input wire [2:0] sw,
    output reg [2:0] led
    );

    localparam A = 3'b000;
    localparam B = 3'b001;
    localparam C = 3'b010;
    localparam D = 3'b011;
    localparam E = 3'b100;

    reg [2:0] state, n_state;
    reg [2:0] led_state;

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
                else n_state = A;
            end
            B : if(sw==3'b010) n_state = C; else n_state = B;
            C : if(sw==3'b100) n_state = D; else n_state = C;
            D : begin
                if(sw==3'b111) n_state = E; 
                else if(sw==3'b000) n_state = A;
                else if(sw==3'b001) n_state = B; else n_state = D;
            end
            E : if(sw==3'b000) n_state = A; else n_state = E;
            default : n_state = A;
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            led <= 3'b000;
        end else begin
            led <= led_state;
        end
    end

    always @(*) begin
        led_state = 3'b000;
        case(state)
            B : led_state[0] = 1;
            C : led_state[1] = 1;
            D : led_state[2] = 1;
            E : led_state = 3'b111;
            default : led_state = 3'b000;
        endcase
    end
endmodule


module fsm5 (
    input wire clk,
    input wire rst_n,
    input wire [2:0] sw,
    output reg [2:0] led
    );

    localparam A = 3'b000;
    localparam B = 3'b001;
    localparam C = 3'b010;
    localparam D = 3'b011;
    localparam E = 3'b100;

    reg [2:0] state, n_state;
    reg [2:0] led_state;

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

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            led <= 3'b000;
        end else begin
            led <= led_state;
        end
    end

    always @(*) begin
        led_state = 3'b000;
        case(state)
            B : led_state[0] = 1;
            C : led_state[1] = 1;
            D : led_state[2] = 1;
            E : led_state = 3'b111;
            default : led_state = 3'b000;
        endcase
    end
endmodule


module fsm6 (
    input wire clk,
    input wire rst_n,
    input wire [2:0] sw,
    output reg [2:0] led
    );

    localparam A = 3'b000;
    localparam B = 3'b001;
    localparam C = 3'b010;
    localparam D = 3'b011;
    localparam E = 3'b100;

    reg [2:0] state, n_state;
    reg [2:0] led_state;

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
        led_state = 3'b000;
        case(state)
            A : begin 
                led_state = 3'b000;
                if(sw==3'b001) n_state = B;
                else if(sw==3'b010) n_state = C;
                else n_state = A;
            end
            B : begin if(sw==3'b010) begin n_state = C; led_state[0] = 1; end else n_state = B; end
            C : begin if(sw==3'b100) begin n_state = D; led_state[1] = 1; end else n_state = C; end
            D : begin
                led_state[2] = 1;
                if(sw==3'b111) n_state = E; 
                else if(sw==3'b000) n_state = A;
                else if(sw==3'b001) n_state = B;
                else n_state = B; 
            end
            E : begin if(sw==3'b000) begin n_state = A; led_state = 3'b111; end else n_state = E; end
            default : begin n_state = A; led_state = 3'b000; end
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            led <= 3'b000;
        end else begin
            led <= led_state;
        end
    end
endmodule