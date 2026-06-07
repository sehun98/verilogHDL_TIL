`timescale 1ns / 1ps

module apb_gpio (
    input logic PCLK,
    input logic PRESETn,

    input logic PSEL,
    input logic PWRITE,
    input logic PENABLE,
    input logic [1:0] PSTRB,
    input logic [31:0] PWDATA,
    input logic [31:0] PADDR,

    output logic PSLVERR,
    output logic PREADY,
    output logic [31:0] PRDATA,

    inout wire [15:0] gpio_pin
);
    logic apb_setup;
    logic apb_access;
    logic apb_read;
    logic apb_write;

    assign apb_setup = PSEL & !PENABLE;
    assign apb_access = PSEL && PENABLE;
    assign apb_read   = apb_access && !PWRITE;
    assign apb_write  = apb_access && PWRITE;

    assign PSLVERR = 1'b0;
    assign PREADY  = 1'b1;

    logic [31:0] gpio_crl;
    logic [31:0] gpio_crh;
    logic [31:0] gpio_idr;
    logic [31:0] gpio_odr;
    logic [31:0] gpio_bsrr;

    logic [15:0] gpio_dir;

    assign gpio_idr = {16'd0, gpio_pin};

    genvar i;
    generate
        for(i = 0; i < 16; i = i + 1) begin
            assign gpio_pin[i] = gpio_dir[i] ? gpio_odr[i] : 1'bz;
        end
    endgenerate

    // CRL/CRH로 방향 결정
    always_comb begin
        gpio_dir = 16'd0;

        for(int j = 0; j < 8; j++) begin
            gpio_dir[j] = (gpio_crl[j*4 +: 2] != 2'b00);
        end

        for(int j = 0; j < 8; j++) begin
            gpio_dir[j+8] = (gpio_crh[j*4 +: 2] != 2'b00);
        end
    end

    // WRITE
    always_ff @(posedge PCLK or negedge PRESETn) begin
        if(!PRESETn) begin
            gpio_crl  <= 32'h0000_0000;
            gpio_crh  <= 32'h0000_0000;
            gpio_odr  <= 32'h0000_0000;
            gpio_bsrr <= 32'h0000_0000;
        end else if(apb_write) begin
            case(PADDR[7:0])
                8'h00: gpio_crl <= PWDATA;
                8'h04: gpio_crh <= PWDATA;
                8'h0C: gpio_odr <= PWDATA;
                8'h10: begin
                    gpio_bsrr <= PWDATA;
                    // BSRR[15:0]  : set
                    // BSRR[31:16] : reset
                    gpio_odr[15:0] <= 
                        (gpio_odr[15:0] | PWDATA[15:0]) & ~(PWDATA[31:16]);
                end
            endcase
        end
    end

    // READ
    always_comb begin
        PRDATA = 32'd0;
        if(apb_read) begin
            case(PADDR[7:0])
                8'h00: PRDATA = gpio_crl;
                8'h04: PRDATA = gpio_crh;
                8'h08: PRDATA = gpio_idr;
                8'h0C: PRDATA = gpio_odr;
                8'h10: PRDATA = gpio_bsrr;
                default: PRDATA = 32'd0;
            endcase
        end
    end

endmodule