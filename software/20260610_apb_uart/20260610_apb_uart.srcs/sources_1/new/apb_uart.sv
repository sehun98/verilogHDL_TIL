`timescale 1ns / 1ps

module apb_uart (
    input logic PCLK,
    input logic PRESETn,

    input logic PSEL,
    input logic PENABLE,
    input logic PWRITE,
    input logic [31:0] PADDR,
    input logic [31:0] PWDATA,
    input logic [3:0] PSTRB,

    output logic [31:0] PRDATA,
    output logic PREADY,
    output logic PSLVERR
);

    logic apb_setup;
    logic apb_access;
    logic apb_read;
    logic apb_write;

    assign apb_setup = PSEL & !PENABLE;
    assign apb_access = PSEL & PENABLE;
    assign apb_read = apb_access & !PWRITE;
    assign apb_write = apb_access & PWRITE;

    // uart Register 
    logic [31:0] A;


    

endmodule

module uart_baudrate (
    input  logic        clk,
    input  logic        rst_n,
    input  logic [31:0] baud,      // 9600, 115200
    output logic        baud_tick
);
    localparam int CLOCK_FREQ_HZ = 100_000_000;

    logic [31:0] count;
    logic [31:0] cnt;

    assign count = CLOCK_FREQ_HZ / (baud * 16);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt       <= 32'd0;
            baud_tick <= 1'b0;
        end else begin
            if (cnt == count - 1) begin
                cnt       <= 32'd0;
                baud_tick <= 1'b1;
            end else begin
                cnt       <= cnt + 1;
                baud_tick <= 1'b0;
            end
        end
    end
endmodule

module uart_tx (
    input  logic       clk,
    input  logic       rst_n,
    input  logic       baud_tick,
    input  logic [7:0] tx_data,
    input  logic       tx_send,
    output logic       tx_busy,

    output logic tx
);

    logic [7:0] tx_reg, tx_next;
    logic [3:0] tick_cnt_reg, tick_cnt_next;  // 2**4 
    logic [2:0] data_idx_reg, data_idx_next;  // 2**3

    typedef enum logic [1:0] {
        IDLE,
        START,
        DATA,
        STOP
    } state_t;

    state_t c_state, n_state;

    assign tx_busy = (c_state != IDLE);

    // 2-process
    // state register
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            c_state <= IDLE;
            tx_reg <= 8'd0;
            tick_cnt_reg <= 4'd0;
            data_idx_reg <= 3'd0;
        end else begin
            c_state <= n_state;
            tx_reg <= tx_next;
            tick_cnt_reg <= tick_cnt_next;
            data_idx_reg <= data_idx_next;
        end
    end

    // next state combinational logic
    always_comb begin
        n_state = c_state;
        tx_next = tx_reg;
        tick_cnt_next = tick_cnt_reg;
        data_idx_next = data_idx_reg;
        tx = 1'd1;
        case (c_state)
            IDLE: begin
                tick_cnt_next = 4'd0;
                data_idx_next = 3'd0;
                if (tx_send) begin
                    tx_next = tx_data;
                    n_state = START;
                end
            end
            START: begin
                tx = 1'd0;
                if (baud_tick) begin
                    if (tick_cnt_reg == 15) begin
                        n_state = DATA;
                        tick_cnt_next = 4'd0;
                    end else begin
                        tick_cnt_next = tick_cnt_reg + 1'd1;
                    end
                end
            end
            DATA: begin
                tx = tx_reg[data_idx_reg];
                if (baud_tick) begin
                    if (tick_cnt_reg == 15) begin
                        if (data_idx_reg == 7) begin
                            data_idx_next = 3'd0;
                            n_state = STOP;
                        end else begin
                            data_idx_next = data_idx_reg + 1'b1;
                        end
                        tick_cnt_next = 4'd0;
                    end else begin
                        tick_cnt_next = tick_cnt_reg + 1'd1;
                    end
                end
            end
            STOP: begin
                tx = 1'd1;
                if(baud_tick) begin
                    if(tick_cnt_reg == 15) begin
                        tick_cnt_next = 4'd0;
                        n_state = IDLE;
                    end else begin
                        tick_cnt_next = tick_cnt_reg + 1'd1;
                    end
                end
            end
        endcase
    end
endmodule
