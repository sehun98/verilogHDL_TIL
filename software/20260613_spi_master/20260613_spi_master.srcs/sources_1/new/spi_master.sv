`timescale 1ns / 1ps

module spi_master (
    input  logic       clk,
    input  logic       reset,
    input  logic       start,
    input  logic       cpol,
    input  logic       cpha,
    input  logic [2:0] clk_div,
    output logic       busy,
    output logic       done,
    input  logic [7:0] tx_data,
    output logic [7:0] rx_data,
    output logic       sclk,
    output logic       mosi,
    input  logic       miso,
    output logic       ss_n
);
    typedef enum logic [1:0] {
        IDLE = 2'b00,
        DATA,
        DONE
    } state_t;

    state_t state;

    logic       sclk_enable;
    logic       tick;
    logic [7:0] tx_shift_reg;
    logic [7:0] rx_shift_reg;
    logic [3:0] edge_cnt;
    logic       sample_edge;
    logic       shift_edge;

    spi_baudrate u1_spi_baudrate (
        .clk    (clk),
        .reset  (reset),
        .enable (sclk_enable),
        .SPI_BR (clk_div[2:0]),
        .tick   (tick)
    );

    assign sample_edge = (cpol ^ cpha) ? (~sclk == 1'b0) : (~sclk == 1'b1);
    assign shift_edge  = (cpol ^ cpha) ? (~sclk == 1'b1) : (~sclk == 1'b0);

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state        <= IDLE;
            sclk_enable  <= 1'b0;
            ss_n         <= 1'b1;
            mosi         <= 1'b0;
            busy         <= 1'b0;
            done         <= 1'b0;
            rx_data      <= 8'd0;
            rx_shift_reg <= 8'd0;
            sclk         <= 1'b0;
            tx_shift_reg <= 8'd0;
            edge_cnt     <= 4'd0;
        end else begin
            case (state)
                IDLE: begin
                    sclk_enable <= 1'b0;
                    ss_n        <= 1'b1;
                    busy        <= 1'b0;
                    done        <= 1'b0;
                    edge_cnt    <= 4'd0;
                    sclk        <= cpol;

                    if (start) begin
                        //rx_data      <= 8'd0;
                        rx_shift_reg <= 8'd0;
                        sclk_enable  <= 1'b1;
                        ss_n         <= 1'b0;
                        busy         <= 1'b1;
                        sclk         <= cpol;
                        edge_cnt     <= 4'd0;

                        if (cpha == 1'b0) begin
                            mosi         <= tx_data[7];
                            tx_shift_reg <= {tx_data[6:0], 1'b0};
                        end else begin
                            mosi         <= 1'b0;
                            tx_shift_reg <= tx_data;
                        end

                        state <= DATA;
                    end
                end

                DATA: begin
                    if (tick) begin
                        sclk <= ~sclk;

                        if (sample_edge) begin
                            rx_shift_reg <= {rx_shift_reg[6:0], miso};

                            if ((cpha == 1'b0 && edge_cnt == 4'd14) ||
                                (cpha == 1'b1 && edge_cnt == 4'd15)) begin
                                rx_data <= {rx_shift_reg[6:0], miso};
                            end
                        end

                        if (shift_edge) begin
                            mosi         <= tx_shift_reg[7];
                            tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
                        end

                        if (sample_edge || shift_edge) begin
                            if (edge_cnt == 4'd15) begin
                                state    <= DONE;
                                edge_cnt <= 4'd0;
                            end else begin
                                edge_cnt <= edge_cnt + 1'b1;
                            end
                        end
                    end
                end

                DONE: begin
                    sclk_enable <= 1'b0;
                    ss_n        <= 1'b1;
                    busy        <= 1'b0;
                    done        <= 1'b1;
                    edge_cnt    <= 4'd0;
                    sclk        <= cpol;
                    state       <= IDLE;
                end

                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule

module spi_baudrate (
    input  logic       clk,
    input  logic       reset,
    input  logic       enable,
    input  logic [2:0] SPI_BR,
    output logic       tick
);
    logic [31:0] cnt;
    logic [31:0] half_count;

    assign half_count = 32'd1 << SPI_BR;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            cnt  <= 32'd0;
            tick <= 1'b0;
        end else begin
            tick <= 1'b0;

            if (enable) begin
                if (cnt == half_count - 1'b1) begin
                    cnt  <= 32'd0;
                    tick <= 1'b1;
                end else begin
                    cnt <= cnt + 1'b1;
                end
            end else begin
                cnt <= 32'd0;
            end
        end
    end
endmodule
