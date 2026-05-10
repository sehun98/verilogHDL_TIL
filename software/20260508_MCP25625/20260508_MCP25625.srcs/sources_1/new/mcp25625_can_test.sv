
`timescale 1ns / 1ps

module mcp25625_can_test (
    input  logic clk,
    input  logic rst_n,

    output logic CS,

    output logic [7:0] spi_tx_data,
    input  logic [7:0] spi_rx_data,
    output logic       spi_request,
    input  logic       spi_done,

    output logic [7:0] canstat_debug
);

    typedef enum logic [2:0] {
        IDLE,
        CS_LOW,
        SEND_BYTE,
        WAIT_DONE,
        CS_HIGH,
        DONE
    } state_t;

    state_t state, n_state;

    logic [1:0] byte_idx_reg, byte_idx_next;

    logic [7:0] tx_seq [0:2];
    logic [7:0] rx_seq_reg [0:2];
    logic [7:0] rx_seq_next [0:2];

    logic cs_reg, cs_next;

    assign CS = cs_reg;
    assign canstat_debug = rx_seq_reg[2];

    integer i;

    always_comb begin
        tx_seq[0] = 8'h03;  // READ instruction
        tx_seq[1] = 8'h0E;  // CANSTAT address
        tx_seq[2] = 8'h00;  // dummy byte
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            cs_reg <= 1'b1;
            byte_idx_reg <= 2'd0;

            for (i = 0; i < 3; i = i + 1) begin
                rx_seq_reg[i] <= 8'd0;
            end
        end else begin
            state <= n_state;
            cs_reg <= cs_next;
            byte_idx_reg <= byte_idx_next;

            for (i = 0; i < 3; i = i + 1) begin
                rx_seq_reg[i] <= rx_seq_next[i];
            end
        end
    end

    always_comb begin
        n_state = state;

        cs_next = cs_reg;
        byte_idx_next = byte_idx_reg;

        spi_tx_data = 8'h00;
        spi_request = 1'b0;

        for (int k = 0; k < 3; k = k + 1) begin
            rx_seq_next[k] = rx_seq_reg[k];
        end

        case (state)
            IDLE: begin
                cs_next = 1'b1;
                byte_idx_next = 2'd0;
                n_state = CS_LOW;
            end

            CS_LOW: begin
                cs_next = 1'b0;
                n_state = SEND_BYTE;
            end

            SEND_BYTE: begin
                spi_tx_data = tx_seq[byte_idx_reg];
                spi_request = 1'b1;
                n_state = WAIT_DONE;
            end

            WAIT_DONE: begin
                spi_request = 1'b0;

                if (spi_done) begin
                    rx_seq_next[byte_idx_reg] = spi_rx_data;

                    if (byte_idx_reg == 2'd2) begin
                        n_state = CS_HIGH;
                    end else begin
                        byte_idx_next = byte_idx_reg + 1'b1;
                        n_state = SEND_BYTE;
                    end
                end
            end

            CS_HIGH: begin
                cs_next = 1'b1;
                n_state = DONE;
            end

            DONE: begin
                n_state = DONE;
            end

            default: begin
                n_state = IDLE;
            end
        endcase
    end

endmodule
