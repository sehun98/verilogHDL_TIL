`timescale 1ns / 1ps

// UART TX
// Format : 115200-8-N-1
// Frame  : start(0) + data[7:0] LSB first + stop(1)

module uart_tx (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       tx_baud_tick,   // 1-bit transmit timing pulse

    input  wire       send,           // transmit request
    output wire       busy,           // transmitter busy
    output reg        done,           // 1-cycle pulse when frame is done

    input  wire [7:0] data,           // transmit data byte
    output reg        tx              // UART TX serial output
);

    // FSM state
    localparam IDLE  = 2'b00;
    localparam START = 2'b01;
    localparam PISO  = 2'b10;         // data bit transmit state
    localparam STOP  = 2'b11;

    reg [1:0] state, n_state;
    reg [2:0] count;                  // data bit index : 0 ~ 7
    reg [7:0] tx_data_reg;            // latched transmit data

    reg send_d;
    reg tx_next;

    // Detect rising edge of send
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            send_d <= 1'b0;
        else
            send_d <= send;
    end

    wire send_pulse = send & ~send_d;

    // 1) State register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= n_state;
    end

    // 2) Next-state logic
    always @(*) begin
        n_state = state;

        case (state)
            IDLE  : if (send_pulse)                 n_state = START;
            START : if (tx_baud_tick)               n_state = PISO;
            PISO  : if (tx_baud_tick && count == 3'd7) n_state = STOP;
            STOP  : if (tx_baud_tick)               n_state = IDLE;
            default:                                n_state = IDLE;
        endcase
    end

    // 3) Latch input data when transmission starts
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            tx_data_reg <= 8'd0;
        else if (state == IDLE && send_pulse)
            tx_data_reg <= data;
    end

    // 4) Data bit counter
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= 3'd0;
        end else begin
            if (tx_baud_tick) begin
                case (state)
                    IDLE: count <= 3'd0;

                    PISO: begin
                        if (count == 3'd7)
                            count <= 3'd0;
                        else
                            count <= count + 3'd1;
                    end

                    default: count <= count;
                endcase
            end
        end
    end

    // 5) TX output register
    // tx is updated only at tx_baud_tick timing
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            tx <= 1'b1;              // UART idle level
        else if (tx_baud_tick)
            tx <= tx_next;
    end

    // 6) TX output combinational logic
    always @(*) begin
        case (state)
            IDLE  : tx_next = 1'b1;
            START : tx_next = 1'b0;
            PISO  : tx_next = tx_data_reg[count];
            STOP  : tx_next = 1'b1;
            default: tx_next = 1'b1;
        endcase
    end

    assign busy = (state != IDLE);

    // 7) Done pulse
    // Assert for 1 clock when stop bit transmission is finished
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            done <= 1'b0;
        end else begin
            done <= 1'b0;
            if (state == STOP && tx_baud_tick)
                done <= 1'b1;
        end
    end

endmodule