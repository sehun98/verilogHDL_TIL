`timescale 1ns / 1ps

module tb_i2c_master ();
    logic clk;
    logic reset;
    logic cmd_start;
    logic cmd_write;
    logic cmd_read;
    logic cmd_stop;
    logic [7:0] tx_data;
    logic [7:0] rx_data;
    logic ack_in;
    logic ack_out;
    logic busy;
    logic done;
    logic scl;
    wire sda;

    i2c_master_top u1_i2c_master_top (
        .clk      (clk),
        .reset    (reset),
        .cmd_start(cmd_start),
        .cmd_write(cmd_write),
        .cmd_read (cmd_read),
        .cmd_stop (cmd_stop),
        .tx_data  (tx_data),
        .rx_data  (rx_data),
        .ack_in   (ack_in),
        .ack_out  (ack_out),
        .done     (done),
        .busy     (busy),
        .scl      (scl),
        .sda      (sda)
    );

    always #5 clk = ~clk;

    initial begin
        reset = 0;
        repeat(2) @(posedge clk);
        reset = 1;
        clk = 0;
        repeat(2) @(posedge clk);
        reset = 0;
        #1000;


        @(posedge clk);

    end

endmodule

module i2c_demo_top (
    input  logic clk,
    input  logic reset,
    input  logic sw,
    output logic scl,
    inout  wire  sda
);

    typedef enum logic [2:0] {
        IDLE  = 0,
        START,
        ADDR,
        WRITE,
        STOP
    } i2c_state_e;

    localparam SLA_W = {7'h12, 1'b0};

    i2c_state_e       state;
    logic       [7:0] counter;
    logic             cmd_start;
    logic             cmd_write;
    logic             cmd_read;
    logic             cmd_stop;
    logic       [7:0] tx_data;
    logic             ack_in;
    logic       [7:0] rx_data;
    logic             done;
    logic             ack_out;
    logic             busy;

    i2c_master_top u1_i2c_master_top (
        .clk      (clk),
        .reset    (reset),
        .cmd_start(cmd_start),
        .cmd_write(cmd_write),
        .cmd_read (cmd_read),
        .cmd_stop (cmd_stop),
        .tx_data  (tx_data),
        .rx_data  (rx_data),
        .ack_in   (ack_in),
        .ack_out  (ack_out),
        .done     (done),
        .busy     (busy),
        .scl      (scl),
        .sda      (sda)
    );

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state     <= IDLE;
            counter   <= 0;
            cmd_start <= 1'b0;
            cmd_write <= 1'b0;
            cmd_read  <= 1'b0;
            cmd_stop  <= 1'b0;
            tx_data   <= 0;
        end else begin
            case (state)
                IDLE: begin
                    cmd_start <= 1'b0;
                    cmd_write <= 1'b0;
                    cmd_read  <= 1'b0;
                    cmd_stop  <= 1'b0;
                    if (sw) begin
                        state <= START;
                    end
                end
                START: begin
                    cmd_start <= 1'b1;
                    cmd_write <= 1'b0;
                    cmd_read  <= 1'b0;
                    cmd_stop  <= 1'b0;
                    if (done) begin
                        state <= ADDR;
                    end
                end
                ADDR: begin
                    cmd_start <= 1'b0;
                    cmd_write <= 1'b1;
                    cmd_read  <= 1'b0;
                    cmd_stop  <= 1'b0;
                    tx_data   <= SLA_W;
                    if (done) begin
                        state <= WRITE;
                    end
                end
                WRITE: begin
                    cmd_start <= 1'b0;
                    cmd_write <= 1'b1;
                    cmd_read  <= 1'b0;
                    cmd_stop  <= 1'b0;
                    tx_data   <= counter;
                    if (done) begin
                        state <= STOP;
                    end
                end
                STOP: begin
                    cmd_start <= 1'b0;
                    cmd_write <= 1'b0;
                    cmd_read  <= 1'b0;
                    cmd_stop  <= 1'b1;
                    if (done) begin
                        state   <= IDLE;
                        counter <= counter + 1;
                    end
                end
                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule
