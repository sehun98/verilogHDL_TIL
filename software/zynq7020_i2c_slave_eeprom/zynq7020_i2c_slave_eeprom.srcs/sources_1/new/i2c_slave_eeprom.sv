`timescale 1ns / 1ps

module i2c_slave_eeprom (
    input  logic       clk,
    input  logic       rst_n,
    input  logic [2:0] chip_select,
    output logic       we,
    output logic [7:0] addr,
    input  logic [7:0] rdata,
    output logic [7:0] wdata,
    input  logic       scl,
    inout  wire        sda
);

    logic sda_i;
    logic sda_o;
    assign sda   = (sda_o == 1'b0) ? 1'b0 : 1'bz;
    assign sda_i = sda;

    typedef enum logic [3:0] {
        IDLE,
        ADDR,
        ADDR_ACK,
        MEM_ADDR,
        MEM_ADDR_ACK,
        WRITE,
        WRITE_ACK,
        READ_LOAD,
        READ,
        READ_ACK
    } state_t;

    state_t state;

    logic scl_sync_1ff, scl_sync_2ff;
    logic sda_sync_1ff, sda_sync_2ff;
    logic scl_sync_d;
    logic sda_sync_d;

    // synchronizer & edge detect
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            scl_sync_1ff <= 1'b1;
            scl_sync_2ff <= 1'b1;
            scl_sync_d   <= 1'b1;
            sda_sync_1ff <= 1'b1;
            sda_sync_2ff <= 1'b1;
            sda_sync_d   <= 1'b1;
        end else begin
            scl_sync_1ff <= scl;
            scl_sync_2ff <= scl_sync_1ff;
            scl_sync_d   <= scl_sync_2ff;
            sda_sync_1ff <= sda_i;
            sda_sync_2ff <= sda_sync_1ff;
            sda_sync_d   <= sda_sync_2ff;
        end
    end

    logic scl_rising_edge, scl_falling_edge;
    logic sda_rising_edge, sda_falling_edge;

    assign scl_rising_edge  = scl_sync_2ff & ~scl_sync_d;
    assign scl_falling_edge = ~scl_sync_2ff & scl_sync_d;
    assign sda_rising_edge  = sda_sync_2ff & ~sda_sync_d;
    assign sda_falling_edge = ~sda_sync_2ff & sda_sync_d;

    logic start_detect;
    logic stop_detect;

    assign start_detect = scl_sync_2ff & sda_falling_edge;
    wire slave_driving = (sda_o == 1'b0);

    assign stop_detect = scl_sync_2ff & sda_rising_edge & ~slave_driving;

    logic [7:0] shift_reg;
    logic [7:0] addr_rw;
    logic [2:0] data_idx;
    logic       ack_active;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            sda_o <= 1'b1;
            addr <= 8'd0;
            wdata <= 8'd0;
            we <= 1'b0;
            shift_reg <= 8'd0;
            addr_rw <= 8'd0;
            data_idx <= 3'd0;
            ack_active <= 1'b0;
        end else begin
            if (stop_detect) begin
                state    <= IDLE;
                sda_o    <= 1'b1;
                we       <= 1'b0;
                data_idx <= 3'd0;
                ack_active <= 1'b0;
            end else if (start_detect) begin
                state     <= ADDR;
                sda_o     <= 1'b1;
                we        <= 1'b0;
                data_idx  <= 3'd0;
                ack_active <= 1'b0;
                shift_reg <= 8'd0;
            end else begin
                case (state)
                    IDLE: begin
                        sda_o <= 1'b1;
                        we <= 1'b0;
                    end
                    ADDR: begin
                        sda_o <= 1'b1;
                        if (scl_rising_edge) begin
                            shift_reg <= {shift_reg[6:0], sda_sync_2ff};
                            if (data_idx == 3'd7) begin
                                addr_rw   <= {shift_reg[6:0], sda_sync_2ff};
                                data_idx  <= 3'd0;
                                shift_reg <= 8'd0;
                                state     <= ADDR_ACK;
                                ack_active <= 1'b0;
                            end else begin
                                data_idx <= data_idx + 1'b1;
                            end
                        end
                    end
                    ADDR_ACK: begin
                        if (addr_rw[7:1] == {4'b1010, chip_select}) begin
                            if (!ack_active) begin
                                if (scl_falling_edge) begin
                                    sda_o      <= 1'b0;
                                    ack_active <= 1'b1;
                                end
                            end else begin
                                sda_o <= 1'b0;
                                if (scl_falling_edge) begin
                                    sda_o       <= 1'b1;
                                    ack_active  <= 1'b0;
                                    shift_reg   <= 8'd0;
                                    data_idx    <= 3'd0;
                                    state       <= addr_rw[0] ? READ_LOAD : MEM_ADDR;
                                end
                            end
                        end else begin
                            sda_o <= 1'b1;
                            state <= IDLE;
                        end
                    end
                    MEM_ADDR: begin
                        if (scl_rising_edge) begin
                            shift_reg <= {shift_reg[6:0], sda_sync_2ff};
                            if (data_idx == 3'd7) begin
                                addr <= {shift_reg[6:0], sda_sync_2ff};
                                data_idx <= 3'd0;
                                state <= MEM_ADDR_ACK;
                                ack_active <= 1'b0;
                            end else begin
                                data_idx <= data_idx + 1'b1;
                            end
                        end
                    end
                    MEM_ADDR_ACK: begin
                        if (!ack_active) begin
                            if (scl_falling_edge) begin
                                sda_o      <= 1'b0;
                                ack_active <= 1'b1;
                            end
                        end else begin
                            sda_o <= 1'b0;
                            if (scl_falling_edge) begin
                                sda_o       <= 1'b1;
                                ack_active  <= 1'b0;
                                shift_reg   <= 8'd0;
                                data_idx    <= 3'd0;
                                state       <= WRITE;
                            end
                        end
                    end
                    WRITE: begin
                        if (scl_rising_edge) begin
                            shift_reg <= {shift_reg[6:0], sda_sync_2ff};
                            if (data_idx == 3'd7) begin
                                wdata <= {shift_reg[6:0], sda_sync_2ff};
                                we <= 1'b1;
                                data_idx <= 3'd0;
                                state <= WRITE_ACK;
                                ack_active <= 1'b0;
                            end else begin
                                data_idx <= data_idx + 1'b1;
                            end
                        end
                    end
                    WRITE_ACK: begin
                        we <= 1'b0;
                        if (!ack_active) begin
                            if (scl_falling_edge) begin
                                sda_o      <= 1'b0;
                                ack_active <= 1'b1;
                            end
                        end else begin
                            sda_o <= 1'b0;
                            if (scl_falling_edge) begin
                                sda_o       <= 1'b1;
                                ack_active  <= 1'b0;
                                addr        <= addr + 1'b1;
                                shift_reg   <= 8'd0;
                                data_idx    <= 3'd0;
                                state       <= WRITE;
                            end
                        end
                    end
                    READ_LOAD: begin
                        shift_reg <= {rdata[6:0], 1'b0};
                        data_idx  <= 3'd0;
                        sda_o     <= rdata[7];
                        state     <= READ;
                    end
                    READ: begin
                        we <= 1'b0;
                        if (scl_falling_edge) begin
                            if (data_idx == 3'd7) begin
                                sda_o    <= 1'b1;
                                data_idx <= 3'd0;
                                state <= READ_ACK;
                            end else begin
                                sda_o <= shift_reg[7];
                                shift_reg <= {shift_reg[6:0], 1'b0};
                                data_idx <= data_idx + 1'b1;
                            end
                        end
                    end
                    READ_ACK: begin
                        we <= 1'b0;
                        sda_o <= 1'b1;
                        if (scl_rising_edge) begin
                            if (sda_sync_2ff == 1'b0) begin
                                addr  <= addr + 1'b1;
                                state <= READ_LOAD;
                            end else begin
                                state <= IDLE;
                            end
                        end
                    end
                    default: begin
                        state    <= IDLE;
                        sda_o    <= 1'b1;
                        we       <= 1'b0;
                        data_idx <= 3'd0;
                    end
                endcase
            end
        end
    end
endmodule
