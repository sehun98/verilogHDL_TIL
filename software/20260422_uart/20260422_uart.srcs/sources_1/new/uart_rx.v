`timescale 1ns / 1ps

// rx_b_tick,
// data output/
// 
// rx input

// done
// busy
// frame_error

// IDLE 
// START
// DATA
// STOP

module uart_rx (
    input wire clk,
    input wire rst_n,
    input wire b_tick,
    output wire [7:0] rx_data,
    output wire rx_done,
    input wire rx
);

    parameter IDLE = 2'b00;
    parameter START = 2'b01;
    parameter DATA = 2'b10;
    parameter STOP = 2'b11;

    reg [1:0] state, n_state;  // 0~3
    reg [7:0] rx_data_reg, rx_data_next;
    reg [4:0] baud_cnt_reg, baud_cnt_next;  // 0~15 -> 23
    reg [2:0] bit_cnt_reg, bit_cnt_next;  // 0~7

    reg rx_sync_1ff;
    reg rx_sync_2ff;

    // 0. rx syncronizer
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_sync_1ff <= 1; // 주의 IDLE 시 1
            rx_sync_2ff <= 1;
        end else begin
            rx_sync_1ff <= rx;
            rx_sync_2ff <= rx_sync_1ff;
        end
    end

    // 1. state & baud count & bit count & output register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            bit_cnt_reg <= 0;
            rx_data_reg <= 0;
            baud_cnt_reg <= 0;
        end else begin
            state <= n_state;
            bit_cnt_reg <= bit_cnt_next;
            rx_data_reg <= rx_data_next;
            baud_cnt_reg <= baud_cnt_next;
        end
    end

    // 2. next state combinational logic
    always @(*) begin
        n_state = state;
        case (state)
            IDLE: begin
                if (!rx_sync_2ff) n_state = START;
            end

            START: begin
                if (b_tick && baud_cnt_reg == 4'd7) begin
                    if (!rx_sync_2ff) n_state = DATA;
                    else n_state = IDLE;  // false start 방지
                end
            end

            DATA: begin
                if (b_tick && baud_cnt_reg == 4'd15 && bit_cnt_reg == 3'd7)
                    n_state = STOP;
            end

            STOP: begin
                if (b_tick && baud_cnt_reg == 4'd15) n_state = IDLE;
            end
        endcase
    end


    // 4. next baud count combinational logic
    always @(*) begin
        baud_cnt_next = baud_cnt_reg;
        case (state)
            IDLE: baud_cnt_next = 4'd0;

            START: begin
                if (b_tick) begin
                    if (baud_cnt_reg == 4'd7) baud_cnt_next = 4'd0;
                    else baud_cnt_next = baud_cnt_reg + 4'd1;
                end
            end

            DATA: begin
                if (b_tick) begin
                    if (baud_cnt_reg == 4'd15) baud_cnt_next = 4'd0;
                    else baud_cnt_next = baud_cnt_reg + 4'd1;
                end
            end

            STOP: begin
                if (b_tick) begin
                    if (baud_cnt_reg == 4'd15) baud_cnt_next = 4'd0;
                    else baud_cnt_next = baud_cnt_reg + 4'd1;
                end
            end
        endcase
    end


    // 4. bit count combinational logic
    always @(*) begin
        bit_cnt_next = bit_cnt_reg;
        case (state)
            IDLE:  bit_cnt_next = 0;
            START: bit_cnt_next = 0;
            DATA: begin
                if (b_tick && baud_cnt_reg == 15) begin
                    if (bit_cnt_reg == 7) bit_cnt_next = 0;
                    else bit_cnt_next = bit_cnt_reg + 1;
                end
            end
            STOP:  bit_cnt_next = 0;
        endcase
    end



    // 5. output combinational logic
    always @(*) begin
        rx_data_next = rx_data_reg;
        case (state)
            IDLE:  rx_data_next = 8'd0;
            START: rx_data_next = 8'd0;
            DATA: begin
                if (b_tick && baud_cnt_reg == 4'd15)
                    rx_data_next[bit_cnt_reg] = rx_sync_2ff;
            end
            STOP:  rx_data_next = rx_data_reg;
        endcase
    end

    assign rx_data = rx_data_reg;

endmodule

module uart_rx_2 (
    input wire clk,
    input wire rst_n,
    input wire b_tick,
    output wire [7:0] rx_data,
    output wire rx_done,
    input wire rx
);

    parameter IDLE = 2'b00;
    parameter START = 2'b01;
    parameter DATA = 2'b10;
    parameter STOP = 2'b11;

    reg [1:0] state, n_state;  // 0~3
    reg [7:0] rx_data_reg, rx_data_next;
    reg [4:0] baud_cnt_reg, baud_cnt_next;  // 0~15 -> 23
    reg [2:0] bit_cnt_reg, bit_cnt_next;  // 0~7
    
    reg rx_done_reg, rx_done_next;  // 0~7

    reg rx_sync_1ff;
    reg rx_sync_2ff;

    assign rx_done = rx_done_reg;
    assign rx_data = rx_data_reg;

    // 0. rx syncronizer
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_sync_1ff <= 1; // 주의 IDLE 시 1
            rx_sync_2ff <= 1;
        end else begin
            rx_sync_1ff <= rx;
            rx_sync_2ff <= rx_sync_1ff;
        end
    end

    // 1. state & baud count & bit count & output register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            bit_cnt_reg <= 0;
            rx_data_reg <= 0;
            baud_cnt_reg <= 0;
            rx_done_reg <= 0;
        end else begin
            state <= n_state;
            bit_cnt_reg <= bit_cnt_next;
            rx_data_reg <= rx_data_next;
            baud_cnt_reg <= baud_cnt_next;
            rx_done_reg <= rx_done_next;
        end
    end

    // 2. next state combinational logic
    always @(*) begin
        n_state = state;
        baud_cnt_next = baud_cnt_reg;
        bit_cnt_next = bit_cnt_reg;
        rx_data_next = rx_data_reg; 
        rx_done_next = rx_done_reg;
        case (state)
            IDLE: begin
                rx_done_next = 0;
                if (b_tick && !rx_sync_2ff) begin 
                    baud_cnt_next = 0;
                    n_state = START;
                end
            end

            START: begin
                if (b_tick) begin
                    if(baud_cnt_reg == 7) begin
                        baud_cnt_next = 0;
                        bit_cnt_next = 0;
                        n_state = DATA;
                    end else begin   
                        baud_cnt_next = baud_cnt_reg +1;
                    end
                end
            end

            DATA: begin
                if (b_tick) begin
                    if(baud_cnt_reg == 15) begin
                        rx_data_next = {rx_sync_2ff, rx_data_reg[7:1]};
                        baud_cnt_next = 0;
                    if(bit_cnt_reg == 7) begin
                            baud_cnt_next = 0;
                            n_state = STOP;
                    end else begin
                        bit_cnt_next = bit_cnt_reg +1;
                    end
                    end else begin
                        baud_cnt_next = baud_cnt_reg + 1;
                    end
                end
            end
            STOP: begin
                if (b_tick) begin
                    if(baud_cnt_reg == 23) begin
                        rx_done_next = 1;
                        n_state = IDLE;
                    end else begin
                        baud_cnt_next = baud_cnt_reg + 1;
                    end
                end
            end
        endcase
    end


endmodule
