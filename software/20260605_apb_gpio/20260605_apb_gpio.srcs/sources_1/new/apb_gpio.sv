`timescale 1ns / 1ps

`define GPIO_CRL   8'h00
`define GPIO_CRH   8'h04
`define GPIO_IDR   8'h08
`define GPIO_ODR   8'h0C
`define GPIO_BSRR  8'h10

module apb_gpio (
    input  logic        PCLK,
    input  logic        PRESETn,

    input  logic        PSEL,
    input  logic        PENABLE,
    input  logic        PWRITE,
    input  logic [31:0] PADDR,
    input  logic [31:0] PWDATA,

    output logic [31:0] PRDATA,
    output logic        PREADY,
    output logic        PSLVERR,

    inout  wire  [15:0] gpio_pin
);

    logic [31:0] gpio_crl;
    logic [31:0] gpio_crh;
    logic [15:0] gpio_odr;
    logic [15:0] gpio_idr;

    logic [15:0] gpio_dir;

    logic apb_setup;
    logic apb_access;
    logic apb_write;
    logic apb_read;

    assign apb_setup = PSEL & !PENABLE;
    assign apb_access = PSEL & PENABLE;
    assign apb_write = apb_access & PWRITE;
    assign apb_read  = apb_access & ~PWRITE;

    assign PREADY  = 1'b1;
    assign PSLVERR = 1'b0;

    // GPIO input read
    assign gpio_idr = gpio_pin;

    // CRL/CRH에서 direction 생성
    // MODE[1:0] == 00이면 input
    // MODE[1:0] != 00이면 output
    genvar i;
    generate
        for (i = 0; i < 8; i++) begin : GEN_CRL_DIR
            assign gpio_dir[i] = | gpio_crl[i*4 +: 2]; // 01 45 89 1213 1617 2021 2425 2829
        end

        for (i = 0; i < 8; i++) begin : GEN_CRH_DIR
            assign gpio_dir[i+8] = | gpio_crh[i*4 +: 2];
        end
    endgenerate

    generate
        for (i = 0; i < 16; i++) begin : GEN_GPIO_PIN
            assign gpio_pin[i] = gpio_dir[i] ? gpio_odr[i] : 1'bz;
        end
    endgenerate

    // APB write register
    always_ff @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            gpio_crl <= 32'd0;
            gpio_crh <= 32'd0;
            gpio_odr <= 16'd0;
        end
        else if (apb_write) begin
            case (PADDR[7:0])
                `GPIO_CRL: gpio_crl <= PWDATA;
                `GPIO_CRH: gpio_crh <= PWDATA;
                `GPIO_ODR: gpio_odr <= PWDATA[15:0];
                `GPIO_BSRR: gpio_odr <= (gpio_odr | PWDATA[15:0]) & ~(PWDATA[31:16]);
            endcase
        end
    end

    // APB read register
    always_comb begin
        PRDATA = 32'd0;
        if (apb_read) begin
            case (PADDR[7:0])
                `GPIO_CRL: PRDATA = gpio_crl;
                `GPIO_CRH: PRDATA = gpio_crh;
                `GPIO_IDR: PRDATA = {16'd0, gpio_idr};
                `GPIO_ODR: PRDATA = {16'd0, gpio_odr};
                `GPIO_BSRR: PRDATA = 32'd0;
            endcase
        end
    end

endmodule