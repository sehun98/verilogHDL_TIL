`timescale 1ns / 1ps

module mcp25625_controller (
    input logic clk,
    input logic rst_n,

    input  logic INT,
    output logic CS,

    // rx output
    output logic [10:0] rx_id,     // standard id 11
    output logic [ 3:0] rx_dlc,
    output logic [ 7:0] rx_data0,
    output logic [ 7:0] rx_data1,
    output logic [ 7:0] rx_data2,
    output logic [ 7:0] rx_data3,
    output logic [ 7:0] rx_data4,
    output logic [ 7:0] rx_data5,
    output logic [ 7:0] rx_data6,
    output logic [ 7:0] rx_data7,

    // rx status
    input  logic rx_ready,
    output logic rx_valid,

    // tx input
    input logic [10:0] tx_id,     // standard id 11
    input logic [ 3:0] tx_dlc,
    input logic [ 7:0] tx_data0,
    input logic [ 7:0] tx_data1,
    input logic [ 7:0] tx_data2,
    input logic [ 7:0] tx_data3,
    input logic [ 7:0] tx_data4,
    input logic [ 7:0] tx_data5,
    input logic [ 7:0] tx_data6,
    input logic [ 7:0] tx_data7,

    // tx status
    input  logic tx_request,
    output logic tx_busy,     // combinational

    // spi master
    output logic [7:0] spi_tx_data,  // combinational
    input  logic [7:0] spi_rx_data,
    output logic       spi_request,  // combinational
    input  logic       spi_done
);
    // 32
    typedef enum logic [4:0] {
        // Initialization
        INIT_SET_CONFIG_MODE,
        INIT_SPEED_SETTING_CFN1,
        INIT_SPEED_SETTING_CFN2,
        INIT_SPEED_SETTING_CFN3,
        // INIT_RESET_BUFF_0,
        // INIT_RESET_BUFF_1,
        // INIT_RESET_BUFF_2,
        // INIT_RESET_BUFF_3,
        // INIT_RESET_BUFF_4,
        // INIT_RESET_BUFF_5,
        INIT_RXB0CTRL_FILTER_SETTING,
        INIT_RXB1CTRL_FILTER_SETTING,
        INIT_RX_INTERRUPT_SETTING,
        INIT_SET_NORMAL_MODE,

        IDLE,

        // RX
        RX_READ_STATUS,
        RX_CHECK_STATUS,
        RX_READ_RXB0_DATA,
        RX_STORE_RXB0,
        RX_CLEAR_RX0IF,

        RX_READ_RXB1_DATA,
        RX_STORE_RXB1,
        RX_CLEAR_RX1IF,

        // TX
        TX_LOAD_TXB0,
        TX_RTS_TXB0,
        TX_READ_STATUS,
        TX_CHECK_TX0IF,
        TX_CLEAR_TX0IF,

        // SPI sequencer
        SEQ_CS_LOW,
        SEQ_SEND_BYTE,
        SEQ_WAIT_DONE,
        SEQ_CS_HIGH
    } state_t;

    state_t state, n_state;
    state_t next_state_after_seq_reg, next_state_after_seq_next;

    logic [7:0] seq_rx_data_next[15:0];
    logic [7:0] seq_rx_data_reg[15:0];

    // can_idh, can_idl, exidh, exidl, dlc, d0, d1, d2, d3, d4, d5, d6, d7
    logic [7:0] seq_data_next[15:0];
    logic [7:0] seq_data_reg[15:0];

    logic [3:0] seq_len_next;
    logic [3:0] seq_len_reg;

    logic [3:0] byte_idx_reg, byte_idx_next;

    logic cs_next, cs_reg;

    logic sync_ff1_INT, sync_ff2_INT;

    integer i, j, k;

    logic [7:0] rx_sidh_next, rx_sidh_reg;
    logic [7:0] rx_sidl_next, rx_sidl_reg;

    logic [3:0] rx_dlc_reg, rx_dlc_next;
    logic [7:0] rx_data0_reg, rx_data0_next;
    logic [7:0] rx_data1_reg, rx_data1_next;
    logic [7:0] rx_data2_reg, rx_data2_next;
    logic [7:0] rx_data3_reg, rx_data3_next;
    logic [7:0] rx_data4_reg, rx_data4_next;
    logic [7:0] rx_data5_reg, rx_data5_next;
    logic [7:0] rx_data6_reg, rx_data6_next;
    logic [7:0] rx_data7_reg, rx_data7_next;

    logic rx_valid_reg, rx_valid_next;

    assign rx_id = {rx_sidh_reg, rx_sidl_reg[7:5]};

    assign tx_busy = (state != IDLE);  // &&&&&&&&&&&&&&&&&&&&
    assign rx_valid = rx_valid_reg;
    assign CS = cs_reg;

    assign rx_dlc = rx_dlc_reg;

    assign rx_data0 = rx_data0_reg;
    assign rx_data1 = rx_data1_reg;
    assign rx_data2 = rx_data2_reg;
    assign rx_data3 = rx_data3_reg;
    assign rx_data4 = rx_data4_reg;
    assign rx_data5 = rx_data5_reg;
    assign rx_data6 = rx_data6_reg;
    assign rx_data7 = rx_data7_reg;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= INIT_SET_CONFIG_MODE;
            sync_ff1_INT <= 1'b1;
            sync_ff2_INT <= 1'b1;
            cs_reg <= 1'b1;
            byte_idx_reg <= 4'd0;
            for (i = 0; i < 16; i = i + 1) begin
                seq_rx_data_reg[i] <= 8'd0;
                seq_data_reg[i] <= 8'd0;
            end
            next_state_after_seq_reg <= IDLE;
            seq_len_reg <= 4'd0;
            rx_valid_reg <= 1'b0;
            rx_sidh_reg <= 8'd0;
            rx_sidl_reg <= 8'd0;
            rx_dlc_reg <= 4'd0;
            rx_data0_reg <= 8'd0;
            rx_data1_reg <= 8'd0;
            rx_data2_reg <= 8'd0;
            rx_data3_reg <= 8'd0;
            rx_data4_reg <= 8'd0;
            rx_data5_reg <= 8'd0;
            rx_data6_reg <= 8'd0;
            rx_data7_reg <= 8'd0;
        end else begin
            state <= n_state;
            sync_ff1_INT <= INT;
            sync_ff2_INT <= sync_ff1_INT;
            cs_reg <= cs_next;
            byte_idx_reg <= byte_idx_next;
            for (j = 0; j < 16; j = j + 1) begin
                seq_rx_data_reg[j] <= seq_rx_data_next[j];
                seq_data_reg[j] <= seq_data_next[j];
            end
            next_state_after_seq_reg <= next_state_after_seq_next;
            seq_len_reg <= seq_len_next;
            rx_valid_reg <= rx_valid_next;
            rx_sidh_reg <= rx_sidh_next;
            rx_sidl_reg <= rx_sidl_next;
            rx_dlc_reg <= rx_dlc_next;
            rx_data0_reg <= rx_data0_next;
            rx_data1_reg <= rx_data1_next;
            rx_data2_reg <= rx_data2_next;
            rx_data3_reg <= rx_data3_next;
            rx_data4_reg <= rx_data4_next;
            rx_data5_reg <= rx_data5_next;
            rx_data6_reg <= rx_data6_next;
            rx_data7_reg <= rx_data7_next;
        end
    end

    always_comb begin
        n_state = state;
        cs_next = cs_reg;

        spi_tx_data = 8'h00;
        spi_request = 1'b0;
        rx_valid_next = rx_valid_reg;

        byte_idx_next = byte_idx_reg;
        seq_len_next = seq_len_reg;
        next_state_after_seq_next = next_state_after_seq_reg;

        rx_sidh_next = rx_sidh_reg;
        rx_sidl_next = rx_sidl_reg;
        rx_dlc_next = rx_dlc_reg;
        rx_data0_next = rx_data0_reg;
        rx_data1_next = rx_data1_reg;
        rx_data2_next = rx_data2_reg;
        rx_data3_next = rx_data3_reg;
        rx_data4_next = rx_data4_reg;
        rx_data5_next = rx_data5_reg;
        rx_data6_next = rx_data6_reg;
        rx_data7_next = rx_data7_reg;

        for (k = 0; k < 16; k = k + 1) begin
            seq_data_next[k]    = seq_data_reg[k];
            seq_rx_data_next[k] = seq_rx_data_reg[k];
        end
        if (rx_valid_reg && rx_ready) begin
            rx_valid_next = 1'b0;
        end

        case (state)
            INIT_SET_CONFIG_MODE: begin
                seq_len_next = 4;

                seq_data_next[0] = 8'h05;
                seq_data_next[1] = 8'h0F;
                seq_data_next[2] = 8'hE0;
                seq_data_next[3] = 8'h80;
                next_state_after_seq_next = INIT_SPEED_SETTING_CFN1;
                n_state = SEQ_CS_LOW;
            end
            INIT_SPEED_SETTING_CFN1: begin
                seq_len_next = 3;

                seq_data_next[0] = 8'h02;
                seq_data_next[1] = 8'h2A;
                seq_data_next[2] = 8'h40;
                next_state_after_seq_next = INIT_SPEED_SETTING_CFN2;
                n_state = SEQ_CS_LOW;
            end
            INIT_SPEED_SETTING_CFN2: begin
                seq_len_next = 3;

                seq_data_next[0] = 8'h02;
                seq_data_next[1] = 8'h29;
                seq_data_next[2] = 8'hBE;
                next_state_after_seq_next = INIT_SPEED_SETTING_CFN3;
                n_state = SEQ_CS_LOW;
            end
            INIT_SPEED_SETTING_CFN3: begin
                seq_len_next = 3;

                seq_data_next[0] = 8'h02;
                seq_data_next[1] = 8'h28;
                seq_data_next[2] = 8'h83;
                //next_state_after_seq_next = INIT_RESET_BUFF_0;
                next_state_after_seq_next = INIT_RXB0CTRL_FILTER_SETTING;
                n_state = SEQ_CS_LOW;
            end
            /*
            // 5.4 WRITE Instruction
            INIT_RESET_BUFF_0: begin
                seq_len_next = 14;

                seq_data_next[0] = 8'h02;
                seq_data_next[1] = 8'h00;

                seq_data_next[2] = 8'h00;  // 0x00
                seq_data_next[3] = 8'h00;  // 0x01
                seq_data_next[4] = 8'h00;  // 0x02
                seq_data_next[5] = 8'h00;  // 0x03
                seq_data_next[6] = 8'h00;  // 0x04
                seq_data_next[7] = 8'h00;  // 0x05
                seq_data_next[8] = 8'h00;  // 0x06
                seq_data_next[9] = 8'h00;  // 0x07
                seq_data_next[10] = 8'h00;  // 0x08
                seq_data_next[11] = 8'h00;  // 0x09
                seq_data_next[12] = 8'h00;  // 0x0A
                seq_data_next[13] = 8'h00;  // 0x0B
                next_state_after_seq_next = INIT_RESET_BUFF_1;
                n_state = SEQ_CS_LOW;
            end
            INIT_RESET_BUFF_1: begin
                seq_len_next = 14;

                seq_data_next[0] = 8'h02;
                seq_data_next[1] = 8'h10;

                seq_data_next[2] = 8'h00;  // 0x10
                seq_data_next[3] = 8'h00;  // 0x11
                seq_data_next[4] = 8'h00;  // 0x12
                seq_data_next[5] = 8'h00;  // 0x13
                seq_data_next[6] = 8'h00;  // 0x14
                seq_data_next[7] = 8'h00;  // 0x15
                seq_data_next[8] = 8'h00;  // 0x16
                seq_data_next[9] = 8'h00;  // 0x17
                seq_data_next[10] = 8'h00;  // 0x18
                seq_data_next[11] = 8'h00;  // 0x19
                seq_data_next[12] = 8'h00;  // 0x1A
                seq_data_next[13] = 8'h00;  // 0x1B
                next_state_after_seq_next = INIT_RESET_BUFF_2;
                n_state = SEQ_CS_LOW;
            end
            INIT_RESET_BUFF_2: begin
                seq_len_next = 10;

                seq_data_next[0] = 8'h02;
                seq_data_next[1] = 8'h20;

                seq_data_next[2] = 8'h00;  // 0x20
                seq_data_next[3] = 8'h00;  // 0x21
                seq_data_next[4] = 8'h00;  // 0x22
                seq_data_next[5] = 8'h00;  // 0x23
                seq_data_next[6] = 8'h00;  // 0x24
                seq_data_next[7] = 8'h00;  // 0x25
                seq_data_next[8] = 8'h00;  // 0x26
                seq_data_next[9] = 8'h00;  // 0x27
                next_state_after_seq_next = INIT_RESET_BUFF_3;
                n_state = SEQ_CS_LOW;
            end
            INIT_RESET_BUFF_3: begin
                seq_len_next = 16;

                seq_data_next[0] = 8'h02;
                seq_data_next[1] = 8'h30;

                seq_data_next[2] = 8'h00;  // 0x30
                seq_data_next[3] = 8'h00;  // 0x31
                seq_data_next[4] = 8'h00;  // 0x32
                seq_data_next[5] = 8'h00;  // 0x33
                seq_data_next[6] = 8'h00;  // 0x34
                seq_data_next[7] = 8'h00;  // 0x35
                seq_data_next[8] = 8'h00;  // 0x36
                seq_data_next[9] = 8'h00;  // 0x37
                seq_data_next[10] = 8'h00;  // 0x38
                seq_data_next[11] = 8'h00;  // 0x39
                seq_data_next[12] = 8'h00;  // 0x3A
                seq_data_next[13] = 8'h00;  // 0x3B
                seq_data_next[14] = 8'h00;  // 0x3C
                seq_data_next[15] = 8'h00;  // 0x3D
                next_state_after_seq_next = INIT_RESET_BUFF_4;
                n_state = SEQ_CS_LOW;
            end
            INIT_RESET_BUFF_4: begin
                seq_len_next = 16;

                seq_data_next[0] = 8'h02;
                seq_data_next[1] = 8'h40;

                seq_data_next[2] = 8'h00;  // 0x10
                seq_data_next[3] = 8'h00;  // 0x11
                seq_data_next[4] = 8'h00;  // 0x12
                seq_data_next[5] = 8'h00;  // 0x13
                seq_data_next[6] = 8'h00;  // 0x14
                seq_data_next[7] = 8'h00;  // 0x15
                seq_data_next[8] = 8'h00;  // 0x16
                seq_data_next[9] = 8'h00;  // 0x17
                seq_data_next[10] = 8'h00;  // 0x18
                seq_data_next[11] = 8'h00;  // 0x19
                seq_data_next[12] = 8'h00;  // 0x1A
                seq_data_next[13] = 8'h00;  // 0x1B
                seq_data_next[14] = 8'h00;  // 0x1C
                seq_data_next[15] = 8'h00;  // 0x1D
                next_state_after_seq_next = INIT_RESET_BUFF_5;
                n_state = SEQ_CS_LOW;
            end
            INIT_RESET_BUFF_5: begin
                seq_len_next = 16;

                seq_data_next[0] = 8'h02;
                seq_data_next[1] = 8'h50;

                seq_data_next[2] = 8'h00;  // 0x50
                seq_data_next[3] = 8'h00;  // 0x51
                seq_data_next[4] = 8'h00;  // 0x52
                seq_data_next[5] = 8'h00;  // 0x53
                seq_data_next[6] = 8'h00;  // 0x54
                seq_data_next[7] = 8'h00;  // 0x55
                seq_data_next[8] = 8'h00;  // 0x56
                seq_data_next[9] = 8'h00;  // 0x57
                seq_data_next[10] = 8'h00;  // 0x58
                seq_data_next[11] = 8'h00;  // 0x59
                seq_data_next[12] = 8'h00;  // 0x5A
                seq_data_next[13] = 8'h00;  // 0x5B
                seq_data_next[14] = 8'h00;  // 0x5C
                seq_data_next[15] = 8'h00;  // 0x5D
                next_state_after_seq_next = INIT_RXB0CTRL_FILTER_SETTING;
                n_state = SEQ_CS_LOW;
            end
            */
            INIT_RXB0CTRL_FILTER_SETTING: begin
                seq_len_next = 3;

                seq_data_next[0] = 8'h02;
                seq_data_next[1] = 8'h60;
                seq_data_next[2] = 8'h64;
                next_state_after_seq_next = INIT_RXB1CTRL_FILTER_SETTING;
                n_state = SEQ_CS_LOW;
            end
            INIT_RXB1CTRL_FILTER_SETTING: begin
                seq_len_next = 3;

                seq_data_next[0] = 8'h02;
                seq_data_next[1] = 8'h70;
                seq_data_next[2] = 8'h60;
                next_state_after_seq_next = INIT_RX_INTERRUPT_SETTING;
                n_state = SEQ_CS_LOW;
            end
            INIT_RX_INTERRUPT_SETTING: begin
                seq_len_next = 4;

                seq_data_next[0] = 8'h05;
                seq_data_next[1] = 8'h2B;
                seq_data_next[2] = 8'h03;
                seq_data_next[3] = 8'h03;
                next_state_after_seq_next = INIT_SET_NORMAL_MODE;
                n_state = SEQ_CS_LOW;
            end
            INIT_SET_NORMAL_MODE: begin
                seq_len_next = 4;

                seq_data_next[0] = 8'h05;
                seq_data_next[1] = 8'h0F;
                seq_data_next[2] = 8'hE0;
                seq_data_next[3] = 8'h00;
                next_state_after_seq_next = IDLE;
                n_state = SEQ_CS_LOW;
            end
            IDLE: begin
                if (!rx_valid_reg && !sync_ff2_INT) begin
                    n_state = RX_READ_STATUS;
                end else if (tx_request) begin
                    n_state = TX_LOAD_TXB0;
                end
            end
            TX_LOAD_TXB0: begin
                seq_len_next = 14;

                seq_data_next[0] = 8'h40;

                seq_data_next[1] = tx_id[10:3];  // SIDH
                seq_data_next[2] = {tx_id[2:0], 1'b0, 4'b0000};  // SIDL

                seq_data_next[3] = 8'h00;
                seq_data_next[4] = 8'h00;

                seq_data_next[5] = {4'b0000, tx_dlc};

                seq_data_next[6] = tx_data0;  // TXB0D0
                seq_data_next[7] = tx_data1;  // TXB0D1
                seq_data_next[8] = tx_data2;  // TXB0D2
                seq_data_next[9] = tx_data3;  // TXB0D3
                seq_data_next[10] = tx_data4;  // TXB0D4
                seq_data_next[11] = tx_data5;  // TXB0D5
                seq_data_next[12] = tx_data6;  // TXB0D6
                seq_data_next[13] = tx_data7;  // TXB0D7
                next_state_after_seq_next = TX_RTS_TXB0;
                n_state = SEQ_CS_LOW;
            end

            TX_RTS_TXB0: begin
                seq_len_next = 1;

                seq_data_next[0] = 8'h81;

                next_state_after_seq_next = TX_READ_STATUS;
                n_state = SEQ_CS_LOW;
            end
            TX_READ_STATUS: begin
                seq_len_next = 2;

                seq_data_next[0] = 8'hA0;
                seq_data_next[1] = 8'h00;

                next_state_after_seq_next = TX_CHECK_TX0IF;
                n_state = SEQ_CS_LOW;
            end
            TX_CHECK_TX0IF: begin
                if (seq_rx_data_reg[1][3]) begin
                    n_state = TX_CLEAR_TX0IF;
                end else begin
                    n_state = TX_READ_STATUS;
                end
            end
            TX_CLEAR_TX0IF: begin
                seq_len_next = 4;

                seq_data_next[0] = 8'h05;
                seq_data_next[1] = 8'h2C;
                seq_data_next[2] = 8'h04;
                seq_data_next[3] = 8'h00;

                next_state_after_seq_next = IDLE;
                n_state = SEQ_CS_LOW;
            end

            RX_READ_STATUS: begin
                seq_len_next = 2;

                seq_data_next[0] = 8'hA0;
                seq_data_next[1] = 8'h00;
                next_state_after_seq_next = RX_CHECK_STATUS;
                n_state = SEQ_CS_LOW;
            end

            RX_CHECK_STATUS: begin
                if (seq_rx_data_reg[1][0]) begin
                    n_state = RX_READ_RXB0_DATA;
                end else if (seq_rx_data_reg[1][1]) begin
                    n_state = RX_READ_RXB1_DATA;
                end else begin
                    n_state = IDLE;
                end
            end
            RX_READ_RXB0_DATA: begin
                seq_len_next = 15;

                seq_data_next[0] = 8'h03;
                seq_data_next[1] = 8'h61;

                seq_data_next[2] = 8'h00;  // SIDH
                seq_data_next[3] = 8'h00;  // SIDL
                seq_data_next[4] = 8'h00;  // EID8
                seq_data_next[5] = 8'h00;  // EID0
                seq_data_next[6] = 8'h00;  // DLC
                seq_data_next[7] = 8'h00;  // D0
                seq_data_next[8] = 8'h00;  // D1
                seq_data_next[9] = 8'h00;  // D2
                seq_data_next[10] = 8'h00;  // D3
                seq_data_next[11] = 8'h00;  // D4
                seq_data_next[12] = 8'h00;  // D5
                seq_data_next[13] = 8'h00;  // D6
                seq_data_next[14] = 8'h00;  // D7
                next_state_after_seq_next = RX_STORE_RXB0;
                n_state = SEQ_CS_LOW;
            end
            RX_STORE_RXB0: begin
                rx_sidh_next = seq_rx_data_reg[2];  // SIDH
                rx_sidl_next = seq_rx_data_reg[3];  // SIDL

                rx_dlc_next = seq_rx_data_reg[6][3:0];  // DLC

                rx_data0_next = seq_rx_data_reg[7];
                rx_data1_next = seq_rx_data_reg[8];
                rx_data2_next = seq_rx_data_reg[9];
                rx_data3_next = seq_rx_data_reg[10];
                rx_data4_next = seq_rx_data_reg[11];
                rx_data5_next = seq_rx_data_reg[12];
                rx_data6_next = seq_rx_data_reg[13];
                rx_data7_next = seq_rx_data_reg[14];

                rx_valid_next = 1'b1;
                n_state = RX_CLEAR_RX0IF;
            end
            RX_CLEAR_RX0IF: begin
                seq_len_next = 4;

                seq_data_next[0] = 8'h05;
                seq_data_next[1] = 8'h2C;
                seq_data_next[2] = 8'h01;
                seq_data_next[3] = 8'h00;
                next_state_after_seq_next = IDLE;
                n_state = SEQ_CS_LOW;
            end
            RX_READ_RXB1_DATA: begin
                seq_len_next = 15;

                seq_data_next[0] = 8'h03;
                seq_data_next[1] = 8'h71;

                seq_data_next[2] = 8'h00;  // SIDH
                seq_data_next[3] = 8'h00;  // SIDL
                seq_data_next[4] = 8'h00;  // EID8
                seq_data_next[5] = 8'h00;  // EID0
                seq_data_next[6] = 8'h00;  // DLC
                seq_data_next[7] = 8'h00;  // D0
                seq_data_next[8] = 8'h00;  // D1
                seq_data_next[9] = 8'h00;  // D2
                seq_data_next[10] = 8'h00;  // D3
                seq_data_next[11] = 8'h00;  // D4
                seq_data_next[12] = 8'h00;  // D5
                seq_data_next[13] = 8'h00;  // D6
                seq_data_next[14] = 8'h00;  // D7
                next_state_after_seq_next = RX_STORE_RXB1;
                n_state = SEQ_CS_LOW;
            end
            RX_STORE_RXB1: begin
                rx_sidh_next = seq_rx_data_reg[2];  // SIDH
                rx_sidl_next = seq_rx_data_reg[3];  // SIDL

                rx_dlc_next = seq_rx_data_reg[6][3:0];  // DLC

                rx_data0_next = seq_rx_data_reg[7];
                rx_data1_next = seq_rx_data_reg[8];
                rx_data2_next = seq_rx_data_reg[9];
                rx_data3_next = seq_rx_data_reg[10];
                rx_data4_next = seq_rx_data_reg[11];
                rx_data5_next = seq_rx_data_reg[12];
                rx_data6_next = seq_rx_data_reg[13];
                rx_data7_next = seq_rx_data_reg[14];

                rx_valid_next = 1'b1;
                n_state = RX_CLEAR_RX1IF;
            end
            RX_CLEAR_RX1IF: begin
                seq_len_next = 4;

                seq_data_next[0] = 8'h05;
                seq_data_next[1] = 8'h2C;
                seq_data_next[2] = 8'h02;
                seq_data_next[3] = 8'h00;
                next_state_after_seq_next = IDLE;
                n_state = SEQ_CS_LOW;
            end

            // sequencer
            SEQ_CS_LOW: begin
                cs_next = 1'b0;
                byte_idx_next = 0;

                n_state = SEQ_SEND_BYTE;
            end
            SEQ_SEND_BYTE: begin
                spi_tx_data = seq_data_reg[byte_idx_reg];
                spi_request = 1'b1;

                n_state = SEQ_WAIT_DONE;
            end
            SEQ_WAIT_DONE: begin
                spi_request = 1'b0;

                if (spi_done) begin
                    seq_rx_data_next[byte_idx_reg] = spi_rx_data;
                    if (byte_idx_reg == seq_len_reg - 1) begin
                        n_state = SEQ_CS_HIGH;
                    end else begin
                        byte_idx_next = byte_idx_reg + 1'b1;
                        n_state = SEQ_SEND_BYTE;
                    end
                end
            end
            SEQ_CS_HIGH: begin
                cs_next = 1'b1;
                n_state = next_state_after_seq_reg;
            end
            default: begin
                n_state = IDLE;
            end
        endcase
    end
endmodule
