`timescale 1ns / 1ps

module i2c_master (
    input logic clk,
    input logic reset,

    input logic cmd_start,
    input logic cmd_write,
    input logic cmd_read,
    input logic cmd_stop,

    input  logic [7:0] tx_data,
    output logic [7:0] rx_data,
    input  logic       ack_in,
    output logic       ack_out,

    output logic busy,
    output logic done,

    inout logic sda,
    inout logic scl
);

    logic sda_o;
    logic sda_i;
    logic scl_o;
    logic scl_i;

    // Open-drain output
    // 0 : drive low
    // 1 : release line
    assign sda = (sda_o == 1'b0) ? 1'b0 : 1'bz;
    assign scl = (scl_o == 1'b0) ? 1'b0 : 1'bz;

    // Pull-up bus value interpretation
    assign sda_i = (sda === 1'b0) ? 1'b0 : 1'b1;
    assign scl_i = (scl === 1'b0) ? 1'b0 : 1'b1;

    typedef enum logic [2:0] {
        IDLE = 3'b000,
        START,
        WAIT_CMD,
        DATA,
        DATA_ACK,
        STOP,
        ARB_LOST
    } i2c_state_e;

    i2c_state_e state;

    logic       qtr_tick;
    logic       scl_r;
    logic       sda_r;
    logic [7:0] div_cnt;
    logic [2:0] bit_cnt;
    logic [1:0] step;
    logic [7:0] tx_shift_reg;
    logic [7:0] rx_shift_reg;
    logic       is_read;
    logic       ack_in_r;

    assign sda_o = sda_r;
    assign scl_o = scl_r;

    assign busy = (state != IDLE);

    // 100MHz / 250 = 400kHz quarter tick
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            div_cnt  <= 8'd0;
            qtr_tick <= 1'b0;
        end else begin
            if (div_cnt == 8'd249) begin
                div_cnt  <= 8'd0;
                qtr_tick <= 1'b1;
            end else begin
                div_cnt  <= div_cnt + 8'd1;
                qtr_tick <= 1'b0;
            end
        end
    end

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state        <= IDLE;
            scl_r        <= 1'b1;  // release
            sda_r        <= 1'b1;  // release
            step         <= 2'd0;
            done         <= 1'b0;
            tx_shift_reg <= 8'd0;
            rx_shift_reg <= 8'd0;
            rx_data      <= 8'd0;
            is_read      <= 1'b0;
            bit_cnt      <= 3'd0;
            ack_in_r     <= 1'b1;
            ack_out      <= 1'b1;
        end else begin
            done <= 1'b0;

            case (state)

                IDLE: begin
                    scl_r <= 1'b1;  // release
                    sda_r <= 1'b1;  // release
                    step  <= 2'd0;

                    if (cmd_start) begin
                        state <= START;
                        step  <= 2'd0;
                    end
                end

                START: begin
                    if (qtr_tick) begin
                        case (step)
                            2'd0: begin
                                sda_r <= 1'b1;
                                scl_r <= 1'b1;
                                step  <= 2'd1;
                            end

                            2'd1: begin
                                sda_r <= 1'b0;
                                scl_r <= 1'b1;
                                step  <= 2'd2;
                            end

                            2'd2: begin
                                sda_r <= 1'b0;
                                scl_r <= 1'b0;
                                step  <= 2'd3;
                            end

                            2'd3: begin
                                sda_r <= 1'b0;
                                scl_r <= 1'b0;
                                step  <= 2'd0;
                                done  <= 1'b1;
                                state <= WAIT_CMD;
                            end
                        endcase
                    end
                end

                WAIT_CMD: begin
                    if (cmd_write) begin
                        tx_shift_reg <= tx_data;
                        bit_cnt      <= 3'd0;
                        step         <= 2'd0;
                        is_read      <= 1'b0;
                        state        <= DATA;
                    end else if (cmd_read) begin
                        rx_shift_reg <= 8'd0;
                        bit_cnt      <= 3'd0;
                        step         <= 2'd0;
                        is_read      <= 1'b1;
                        ack_in_r     <= ack_in;
                        state        <= DATA;
                    end else if (cmd_stop) begin
                        step  <= 2'd0;
                        state <= STOP;
                    end else if (cmd_start) begin
                        step  <= 2'd0;
                        state <= START;
                    end
                end

                DATA: begin
                    if (qtr_tick) begin
                        case (step)

                            // SCL low, data setup
                            2'd0: begin
                                scl_r <= 1'b0;
                                sda_r <= is_read ? 1'b1 : tx_shift_reg[7];
                                step  <= 2'd1;
                            end

                            // SCL release high
                            2'd1: begin
                                scl_r <= 1'b1;
                                step  <= 2'd2;
                            end

                            // SCL high, arbitration/sample point
                            2'd2: begin
                                scl_r <= 1'b1;

                                // Arbitration check only during write bit
                                // I release SDA for logic 1, but bus is 0 -> lost
                                if (!is_read &&
                                    tx_shift_reg[7] == 1'b1 &&
                                    sda_i == 1'b0) begin

                                    sda_r <= 1'b1;  // release SDA
                                    scl_r <= 1'b1;  // release SCL
                                    step  <= 2'd0;
                                    done  <= 1'b1;
                                    state <= ARB_LOST;

                                end else begin
                                    step <= 2'd3;
                                end
                            end

                            // SCL low, shift data
                            2'd3: begin
                                scl_r <= 1'b0;
                                step  <= 2'd0;

                                if (is_read) begin
                                    rx_shift_reg <= {rx_shift_reg[6:0], sda_i};
                                end else begin
                                    tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
                                end

                                if (bit_cnt == 3'd7) begin
                                    state <= DATA_ACK;
                                end else begin
                                    bit_cnt <= bit_cnt + 3'd1;
                                end
                            end
                        endcase
                    end
                end

                DATA_ACK: begin
                    if (qtr_tick) begin
                        case (step)

                            2'd0: begin
                                scl_r <= 1'b0;
                                sda_r <= is_read ? ack_in_r : 1'b1;
                                step  <= 2'd1;
                            end

                            2'd1: begin
                                scl_r <= 1'b1;
                                step  <= 2'd2;
                            end

                            2'd2: begin
                                scl_r <= 1'b1;

                                if (!is_read) begin
                                    ack_out <= sda_i;
                                end else begin
                                    rx_data <= rx_shift_reg;
                                end

                                step <= 2'd3;
                            end

                            2'd3: begin
                                scl_r <= 1'b0;
                                sda_r <= 1'b1;
                                step  <= 2'd0;
                                done  <= 1'b1;
                                state <= WAIT_CMD;
                            end
                        endcase
                    end
                end

                STOP: begin
                    if (qtr_tick) begin
                        case (step)

                            2'd0: begin
                                sda_r <= 1'b0;
                                scl_r <= 1'b0;
                                step  <= 2'd1;
                            end

                            2'd1: begin
                                sda_r <= 1'b0;
                                scl_r <= 1'b1;
                                step  <= 2'd2;
                            end

                            2'd2: begin
                                sda_r <= 1'b1;
                                scl_r <= 1'b1;
                                step  <= 2'd3;
                            end

                            2'd3: begin
                                sda_r <= 1'b1;
                                scl_r <= 1'b1;
                                step  <= 2'd0;
                                done  <= 1'b1;
                                state <= IDLE;
                            end
                        endcase
                    end
                end

                ARB_LOST: begin
                    // Lost master releases both lines and returns to IDLE.
                    sda_r <= 1'b1;
                    scl_r <= 1'b1;
                    step  <= 2'd0;
                    state <= IDLE;
                end

                default: begin
                    state <= IDLE;
                    sda_r <= 1'b1;
                    scl_r <= 1'b1;
                    step  <= 2'd0;
                end
            endcase
        end
    end

endmodule