`timescale 1ns / 1ps

module control_board #(
    parameter integer CLK_FREQ_HZ = 100_000_000,
    parameter integer DEBOUNCE_MS = 20
) (
    input logic clk,
    input logic rst_n,
    // FND Control
    output logic [3:0] digit,
    output logic [7:0] seg,

    // SW address 
    input logic [2:0] chip_select,

    // BTN write / read
    input logic btn_write,
    input logic btn_read,

    output logic scl,
    inout  wire  sda
);
    logic        w_tick;
    logic [13:0] w_count;


    logic        w_cmd_start;
    logic        w_cmd_write;
    logic        w_cmd_read;
    logic        w_cmd_stop;

    logic [ 7:0] w_tx_data;
    logic [ 7:0] w_rx_data;
    logic        w_ack_in;
    logic        w_ack_out;
    logic        w_busy;
    logic        w_done;

    logic        w_count_we;
    logic [13:0] w_count_update;
    logic [13:0] w_data;

    logic        w_btn_write;
    logic        w_btn_read;

    assign w_data = w_count;

    tick_1hz #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ)
    ) u1_tick_1hz (
        .clk  (clk),
        .rst_n(rst_n),
        .tick (w_tick)
    );

    counter u2_counter (
        .clk(clk),
        .rst_n(rst_n),
        .we(w_tick),
        .count_we(w_count_we),
        .count_update(w_count_update),
        .count(w_count)
    );

    FND_Controller u3_FND_Controller (
        .clk  (clk),
        .rst_n(rst_n),
        .data (w_data),
        .digit(digit),
        .seg  (seg)
    );

    i2c_master u4_i2c_master (
        .clk  (clk),
        .reset(!rst_n),

        .cmd_start(w_cmd_start),
        .cmd_write(w_cmd_write),
        .cmd_read (w_cmd_read),
        .cmd_stop (w_cmd_stop),
        .tx_data(w_tx_data),
        .rx_data(w_rx_data),
        .ack_in (w_ack_in),
        .ack_out(w_ack_out),
        .busy   (w_busy),
        .done   (w_done),

        .scl(scl),
        .sda(sda)
    );

    control_unit u5_control_unit (
        .clk  (clk),
        .rst_n(rst_n),

        .chip_select(chip_select),
        .btn_write(w_btn_write),
        .btn_read(w_btn_read),

        .cmd_start(w_cmd_start),
        .cmd_write(w_cmd_write),
        .cmd_read (w_cmd_read),
        .cmd_stop (w_cmd_stop),
        .tx_data(w_tx_data),
        .rx_data(w_rx_data),
        .ack_in (w_ack_in),
        .ack_out(w_ack_out),
        .busy   (w_busy),
        .done   (w_done),

        .count_we(w_count_we),
        .count_update(w_count_update),

        .count(w_count)
    );

    btn_interface #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ),
        .DEBOUNCE_MS(DEBOUNCE_MS)
    ) u6_btn_interface (
        .clk(clk),
        .rst_n(rst_n),
        .btn_in(btn_write),
        .btn_pulse(w_btn_write)
    );

    btn_interface #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ),
        .DEBOUNCE_MS(DEBOUNCE_MS)
    ) u7_btn_interface (
        .clk(clk),
        .rst_n(rst_n),
        .btn_in(btn_read),
        .btn_pulse(w_btn_read)
    );

endmodule

module tick_1hz #(
    parameter integer CLK_FREQ_HZ = 100_000_000
) (
    input  logic clk,
    input  logic rst_n,
    output logic tick
);
    localparam COUNT = $clog2(CLK_FREQ_HZ);

    logic [COUNT-1:0] cnt;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt  <= 0;
            tick <= 1'b0;
        end else begin
            if (cnt == CLK_FREQ_HZ - 1) begin
                cnt  <= 0;
                tick <= 1'b1;
            end else begin
                cnt  <= cnt + 1'b1;
                tick <= 1'b0;
            end
        end
    end
endmodule

module counter (
    input logic clk,
    input logic rst_n,
    input logic we,
    input logic count_we,
    input logic [13:0] count_update,
    output logic [13:0] count
);
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= 14'd0;
        end else begin
            if (count_we) begin
                count <= count_update;
            end else if (we) begin
                if (count == 9999) begin
                    count <= 14'd0;
                end else begin
                    count <= count + 1'b1;
                end
            end
        end
    end
endmodule

module control_unit (
    input logic clk,
    input logic rst_n,

    input logic [2:0] chip_select,

    input logic btn_write,
    input logic btn_read,

    output logic cmd_start,
    output logic cmd_write,
    output logic cmd_read,
    output logic cmd_stop,

    output logic [7:0] tx_data,
    input  logic [7:0] rx_data,

    output logic ack_in,
    input  logic ack_out,

    input logic busy,
    input logic done,

    output logic count_we,
    output logic [13:0] count_update,

    input  logic [13:0] count
);

    typedef enum logic [1:0] {
        IDLE  = 2'b00,
        WRITE,
        READ
    } state_t;

    state_t state;

    typedef enum logic [3:0] {
        WRITE_START,
        WRITE_START_ACK,
        WRITE_ADDR,
        WRITE_ADDR_ACK,
        WRITE_MEM_ADDR,
        WRITE_MEM_ADDR_ACK,
        WRITE_DATA,
        WRITE_DATA_ACK,
        WRITE_STOP,
        WRITE_STOP_ACK
    } write_step_t;

    write_step_t write_step;

    typedef enum logic [3:0] {
        READ_START,
        READ_START_ACK,

        READ_ADDR_W,
        READ_ADDR_W_ACK,

        READ_MEM_ADDR,
        READ_MEM_ADDR_ACK,

        READ_RESTART,
        READ_RESTART_ACK,

        READ_ADDR_R,
        READ_ADDR_R_ACK,

        READ_DATA,
        READ_DATA_ACK,

        READ_STOP,
        READ_STOP_ACK
    } read_step_t;

    read_step_t read_step;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state        <= IDLE;
            write_step   <= WRITE_START;
            read_step    <= READ_START;
            cmd_start    <= 0;
            cmd_write    <= 0;
            cmd_read     <= 0;
            cmd_stop     <= 0;
            ack_in       <= 1;
            count_we     <= 0;
            count_update <= 0;
        end else begin
            count_we <= 1'b0;
            case (state)
                IDLE: begin
                    if (btn_write) begin
                        state <= WRITE;
                    end else if (btn_read) begin
                        state <= READ;
                    end
                end
                WRITE: begin
                    case (write_step)
                        WRITE_START: begin
                            cmd_start  <= 1'b1;
                            write_step <= WRITE_START_ACK;
                        end
                        WRITE_START_ACK: begin
                            cmd_start <= 1'b0;
                            if (done) begin
                                write_step <= WRITE_ADDR;
                            end
                        end
                        WRITE_ADDR: begin
                            tx_data    <= {4'b1010, chip_select, 1'b0};
                            cmd_write  <= 1'b1;
                            write_step <= WRITE_ADDR_ACK;
                        end
                        WRITE_ADDR_ACK: begin
                            cmd_write <= 1'b0;
                            if (done) begin
                                if (ack_out == 1'b0)
                                    write_step <= WRITE_MEM_ADDR;
                                else write_step <= WRITE_STOP;
                            end
                        end
                        WRITE_MEM_ADDR: begin
                            tx_data    <= 8'h10; // 읽을 주소 위치
                            cmd_write  <= 1'b1;
                            write_step <= WRITE_MEM_ADDR_ACK;
                        end
                        WRITE_MEM_ADDR_ACK: begin
                            cmd_write <= 1'b0;
                            if (done) begin
                                if (ack_out == 1'b0) write_step <= WRITE_DATA;
                                else write_step <= WRITE_STOP;
                            end
                        end
                        WRITE_DATA: begin
                            tx_data    <= count[7:0];
                            cmd_write  <= 1'b1;
                            write_step <= WRITE_DATA_ACK;
                        end
                        WRITE_DATA_ACK: begin
                            cmd_write <= 1'b0;
                            if (done) begin
                                if (ack_out == 1'b0) write_step <= WRITE_STOP;
                                else write_step <= WRITE_STOP;
                            end
                        end
                        WRITE_STOP: begin
                            cmd_stop   <= 1'b1;
                            write_step <= WRITE_STOP_ACK;
                        end
                        WRITE_STOP_ACK: begin
                            cmd_stop <= 1'b0;
                            if (done) begin
                                write_step <= WRITE_START;
                                state      <= IDLE;
                            end
                        end
                        default: begin
                            cmd_start  <= 1'b0;
                            cmd_write  <= 1'b0;
                            cmd_read   <= 1'b0;
                            cmd_stop   <= 1'b0;
                            write_step <= WRITE_START;
                            state      <= IDLE;
                        end
                    endcase
                end
                READ: begin
                    case (read_step)
                        READ_START: begin
                            cmd_start <= 1'b1;
                            read_step <= READ_START_ACK;
                        end
                        READ_START_ACK: begin
                            cmd_start <= 1'b0;
                            if (done) read_step <= READ_ADDR_W;
                        end
                        READ_ADDR_W: begin
                            tx_data   <= {4'b1010, chip_select, 1'b0};
                            cmd_write <= 1'b1;
                            read_step <= READ_ADDR_W_ACK;
                        end
                        READ_ADDR_W_ACK: begin
                            cmd_write <= 1'b0;
                            if (done) begin
                                if (ack_out == 1'b0) read_step <= READ_MEM_ADDR;
                                else read_step <= READ_STOP;
                            end
                        end
                        READ_MEM_ADDR: begin
                            tx_data   <= 8'h10;
                            cmd_write <= 1'b1;
                            read_step <= READ_MEM_ADDR_ACK;
                        end
                        READ_MEM_ADDR_ACK: begin
                            cmd_write <= 1'b0;
                            if (done) begin
                                if (ack_out == 1'b0) read_step <= READ_RESTART;
                                else read_step <= READ_STOP;
                            end
                        end
                        READ_RESTART: begin
                            cmd_start <= 1'b1;
                            read_step <= READ_RESTART_ACK;
                        end
                        READ_RESTART_ACK: begin
                            cmd_start <= 1'b0;
                            if (done) read_step <= READ_ADDR_R;
                        end
                        READ_ADDR_R: begin
                            tx_data   <= {4'b1010, chip_select, 1'b1};
                            cmd_write <= 1'b1;
                            read_step <= READ_ADDR_R_ACK;
                        end
                        READ_ADDR_R_ACK: begin
                            cmd_write <= 1'b0;
                            if (done) begin
                                if (ack_out == 1'b0) read_step <= READ_DATA;
                                else read_step <= READ_STOP;
                            end
                        end
                        READ_DATA: begin
                            ack_in    <= 1'b1;
                            cmd_read  <= 1'b1;
                            read_step <= READ_DATA_ACK;
                        end
                        READ_DATA_ACK: begin
                            cmd_read <= 1'b0;
                            if (done) begin
                                count_update <= {6'd0, rx_data};
                                count_we     <= 1'b1;
                                read_step    <= READ_STOP;
                            end
                        end
                        READ_STOP: begin
                            cmd_stop  <= 1'b1;
                            read_step <= READ_STOP_ACK;
                        end
                        READ_STOP_ACK: begin
                            cmd_stop <= 1'b0;
                            if (done) begin
                                read_step <= READ_START;
                                state     <= IDLE;
                            end
                        end
                        default: begin
                            read_step <= READ_START;
                            state     <= IDLE;
                        end
                    endcase
                end
            endcase
        end
    end
endmodule
