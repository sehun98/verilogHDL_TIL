`timescale 1ns / 1ps

// I2C_CR [0] : I2C_EN
// I2C_CR [1] : I2C_START  // command bit, rising-edge pulse로 사용
// I2C_CR [2] : I2C_STOP   // command bit, rising-edge pulse로 사용
// I2C_CR [3] : I2C_WRITE  // command bit, rising-edge pulse로 사용
// I2C_CR [4] : I2C_READ   // command bit, rising-edge pulse로 사용
// I2C_CR [5] : I2C_ACK    // 1: ACK send, 0: NACK send during read

// I2C_SR [0] : BUSY
// I2C_SR [1] : DONE
// I2C_SR [2] : NACK   // 1이면 NACK 발생
// I2C_SR [3] : ARLOS  // arbitration lost

// I2C_CLKDIV = SYS_CLK / (I2C_SCL_FREQ * 4)
// 100MHz 기준 100kHz I2C => 100_000_000 / (100_000 * 4) = 250

module i2c_master_core (
    input  logic        clk,
    input  logic        rst_n,

    input  logic [31:0] I2C_CR,
    output logic [31:0] I2C_SR,
    input  logic [31:0] I2C_WDATA,
    output logic [31:0] I2C_RDATA,
    input  logic [31:0] I2C_CLKDIV,
    
    inout  logic        sda,
    inout  logic        scl
);

    logic qtr_tick;

    logic sda_o;
    logic sda_i;
    logic scl_o;
    logic scl_i;

    logic [2:0] bit_cnt;
    logic [1:0] step;
    logic [7:0] tx_shift_reg;
    logic [7:0] rx_shift_reg;

    logic is_read;
    logic ack_in_r;

    logic i2c_en;
    logic ack_in;

    logic [31:0] cr_d;

    logic cmd_start_pulse;
    logic cmd_stop_pulse;
    logic cmd_write_pulse;
    logic cmd_read_pulse;

    logic done_flag;
    logic nack_flag;
    logic arlos_flag;
    logic busy_flag;

    assign i2c_en = I2C_CR[0];
    assign ack_in = I2C_CR[5];

    // Command bits are treated as rising-edge pulses.
    // Software should write command bit 0 -> 1 for each command,
    // or AXI wrapper should generate one-cycle command pulses.
    assign cmd_start_pulse = I2C_CR[1] & ~cr_d[1];
    assign cmd_stop_pulse  = I2C_CR[2] & ~cr_d[2];
    assign cmd_write_pulse = I2C_CR[3] & ~cr_d[3];
    assign cmd_read_pulse  = I2C_CR[4] & ~cr_d[4];

    // Open-drain output
    // sda_o/scl_o = 0 : drive low
    // sda_o/scl_o = 1 : release line
    assign sda = (sda_o == 1'b0) ? 1'b0 : 1'bz;
    assign scl = (scl_o == 1'b0) ? 1'b0 : 1'bz;

    // Pull-up bus value interpretation
    assign sda_i = (sda === 1'b0) ? 1'b0 : 1'b1;
    assign scl_i = (scl === 1'b0) ? 1'b0 : 1'b1;

    typedef enum logic [2:0] {
        IDLE     = 3'd0,
        START    = 3'd1,
        WAIT_CMD = 3'd2,
        DATA     = 3'd3,
        DATA_ACK = 3'd4,
        STOP     = 3'd5,
        ARB_LOST = 3'd6
    } i2c_state_e;

    i2c_state_e state;

    assign busy_flag = (state != IDLE);

    assign I2C_SR = {
        28'd0,
        arlos_flag,   // [3]
        nack_flag,    // [2]
        done_flag,    // [1]
        busy_flag     // [0]
    };

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state        <= IDLE;

            scl_o        <= 1'b1;
            sda_o        <= 1'b1;

            step         <= 2'd0;
            bit_cnt      <= 3'd0;

            tx_shift_reg <= 8'd0;
            rx_shift_reg <= 8'd0;
            I2C_RDATA    <= 32'd0;

            is_read      <= 1'b0;
            ack_in_r     <= 1'b1;

            done_flag    <= 1'b0;
            nack_flag    <= 1'b0;
            arlos_flag   <= 1'b0;

            cr_d         <= 32'd0;
        end else begin
            cr_d <= I2C_CR;

            // Disable이면 즉시 bus release
            if (!i2c_en) begin
                state      <= IDLE;
                scl_o      <= 1'b1;
                sda_o      <= 1'b1;
                step       <= 2'd0;
                bit_cnt    <= 3'd0;
                is_read    <= 1'b0;
                done_flag  <= 1'b0;
                nack_flag  <= 1'b0;
                arlos_flag <= 1'b0;
            end else begin

                // 새 command가 들어오면 이전 DONE은 clear
                if (cmd_start_pulse || cmd_stop_pulse || cmd_write_pulse || cmd_read_pulse) begin
                    done_flag <= 1'b0;
                end

                case (state)

                    IDLE: begin
                        scl_o <= 1'b1;
                        sda_o <= 1'b1;
                        step  <= 2'd0;

                        if (cmd_start_pulse) begin
                            state <= START;
                            step  <= 2'd0;
                        end
                    end

                    START: begin
                        if (qtr_tick) begin
                            case (step)
                                2'd0: begin
                                    // bus idle/repeated-start preparation
                                    sda_o <= 1'b1;
                                    scl_o <= 1'b1;
                                    step  <= 2'd1;
                                end

                                2'd1: begin
                                    // START condition: SDA falling while SCL high
                                    sda_o <= 1'b0;
                                    scl_o <= 1'b1;
                                    step  <= 2'd2;
                                end

                                2'd2: begin
                                    sda_o <= 1'b0;
                                    scl_o <= 1'b0;
                                    step  <= 2'd3;
                                end

                                2'd3: begin
                                    sda_o     <= 1'b0;
                                    scl_o     <= 1'b0;
                                    step      <= 2'd0;
                                    done_flag <= 1'b1;
                                    state     <= WAIT_CMD;
                                end
                            endcase
                        end
                    end

                    WAIT_CMD: begin
                        step <= 2'd0;

                        if (cmd_write_pulse) begin
                            tx_shift_reg <= I2C_WDATA[7:0];
                            bit_cnt      <= 3'd0;
                            is_read      <= 1'b0;
                            state        <= DATA;
                        end else if (cmd_read_pulse) begin
                            rx_shift_reg <= 8'd0;
                            bit_cnt      <= 3'd0;
                            is_read      <= 1'b1;
                            ack_in_r     <= ack_in;
                            state        <= DATA;
                        end else if (cmd_stop_pulse) begin
                            state <= STOP;
                        end else if (cmd_start_pulse) begin
                            state <= START;
                        end
                    end

                    DATA: begin
                        if (qtr_tick) begin
                            case (step)

                                // SCL low, data setup
                                2'd0: begin
                                    scl_o <= 1'b0;

                                    if (is_read) begin
                                        // release SDA for slave to drive
                                        sda_o <= 1'b1;
                                    end else begin
                                        // open-drain:
                                        // tx bit 0 -> drive low
                                        // tx bit 1 -> release
                                        sda_o <= tx_shift_reg[7];
                                    end

                                    step <= 2'd1;
                                end

                                // SCL release high
                                2'd1: begin
                                    scl_o <= 1'b1;
                                    step  <= 2'd2;
                                end

                                // SCL high, arbitration/sample point
                                2'd2: begin
                                    scl_o <= 1'b1;

                                    // Arbitration check during write only.
                                    // If master releases SDA for 1 but bus is 0, arbitration lost.
                                    if (!is_read &&
                                        tx_shift_reg[7] == 1'b1 &&
                                        sda_i == 1'b0) begin

                                        sda_o      <= 1'b1;
                                        scl_o      <= 1'b1;
                                        step       <= 2'd0;
                                        done_flag  <= 1'b1;
                                        arlos_flag <= 1'b1;
                                        state      <= ARB_LOST;

                                    end else begin
                                        step <= 2'd3;
                                    end
                                end

                                // SCL low, shift data
                                2'd3: begin
                                    scl_o <= 1'b0;
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
                                    scl_o <= 1'b0;

                                    if (is_read) begin
                                        // Master sends ACK/NACK after receiving byte.
                                        // I2C_ACK = 1 -> ACK  -> drive SDA low
                                        // I2C_ACK = 0 -> NACK -> release SDA
                                        sda_o <= (ack_in_r) ? 1'b0 : 1'b1;
                                    end else begin
                                        // Release SDA so slave can ACK/NACK
                                        sda_o <= 1'b1;
                                    end

                                    step <= 2'd1;
                                end

                                2'd1: begin
                                    scl_o <= 1'b1;
                                    step  <= 2'd2;
                                end

                                2'd2: begin
                                    scl_o <= 1'b1;

                                    if (!is_read) begin
                                        // Slave ACK/NACK sampling
                                        // SDA 0 = ACK, SDA 1 = NACK
                                        nack_flag <= sda_i;
                                    end else begin
                                        I2C_RDATA <= {24'd0, rx_shift_reg};
                                    end

                                    step <= 2'd3;
                                end

                                2'd3: begin
                                    scl_o     <= 1'b0;
                                    sda_o     <= 1'b1;
                                    step      <= 2'd0;
                                    done_flag <= 1'b1;
                                    state     <= WAIT_CMD;
                                end
                            endcase
                        end
                    end

                    STOP: begin
                        if (qtr_tick) begin
                            case (step)

                                2'd0: begin
                                    sda_o <= 1'b0;
                                    scl_o <= 1'b0;
                                    step  <= 2'd1;
                                end

                                2'd1: begin
                                    sda_o <= 1'b0;
                                    scl_o <= 1'b1;
                                    step  <= 2'd2;
                                end

                                2'd2: begin
                                    // STOP condition: SDA rising while SCL high
                                    sda_o <= 1'b1;
                                    scl_o <= 1'b1;
                                    step  <= 2'd3;
                                end

                                2'd3: begin
                                    sda_o     <= 1'b1;
                                    scl_o     <= 1'b1;
                                    step      <= 2'd0;
                                    done_flag <= 1'b1;
                                    state     <= IDLE;
                                end
                            endcase
                        end
                    end

                    ARB_LOST: begin
                        sda_o <= 1'b1;
                        scl_o <= 1'b1;
                        step  <= 2'd0;
                        state <= IDLE;
                    end

                    default: begin
                        state <= IDLE;
                        sda_o <= 1'b1;
                        scl_o <= 1'b1;
                        step  <= 2'd0;
                    end
                endcase
            end
        end
    end

    i2c_clock_div u1_i2c_clock_div (
        .clk       (clk),
        .rst_n     (rst_n),
        .I2C_CLKDIV(I2C_CLKDIV),
        .qtr_tick  (qtr_tick)
    );

endmodule


module i2c_clock_div (
    input  logic        clk,
    input  logic        rst_n,
    input  logic [31:0] I2C_CLKDIV,
    output logic        qtr_tick
);

    logic [31:0] cnt;
    logic [31:0] div_value;

    assign div_value = (I2C_CLKDIV == 32'd0) ? 32'd1 : I2C_CLKDIV;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            qtr_tick <= 1'b0;
            cnt      <= 32'd0;
        end else begin
            qtr_tick <= 1'b0;

            if (cnt >= div_value - 32'd1) begin
                cnt      <= 32'd0;
                qtr_tick <= 1'b1;
            end else begin
                cnt <= cnt + 32'd1;
            end
        end
    end

endmodule