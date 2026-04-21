module uart_baud_rate (
    input  wire clk,
    input  wire rst_n,
    output reg  tx_baud_tick,
    output reg  rx_baud_tick
);

    parameter CLOCK_FREQ_HZ = 100_000_000;
    parameter BAUD_RATE = 115200;

    localparam TX_BAUD_RATE = BAUD_RATE;
    localparam RX_BAUD_RATE = BAUD_RATE * 16;
    localparam COUNT_WIDTH = $clog2(CLOCK_FREQ_HZ);

    reg [COUNT_WIDTH:0] tx_count;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_count <= 0;
            tx_baud_tick <= 0;
        end else begin
            tx_count <= tx_count + TX_BAUD_RATE;
            tx_baud_tick <= 0;
            if (tx_count + TX_BAUD_RATE >= CLOCK_FREQ_HZ) begin
                tx_count <= tx_count + TX_BAUD_RATE - CLOCK_FREQ_HZ;
                tx_baud_tick <= 1;
            end
        end
    end
endmodule
