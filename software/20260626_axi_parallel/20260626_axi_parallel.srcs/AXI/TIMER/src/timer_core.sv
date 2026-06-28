`timescale 1ns / 1ps

module timer_core (
    input logic clk,
    input logic rst_n,

    input  logic [31:0] TIM_CR,
    output logic [31:0] TIM_CNT,
    input  logic [31:0] TIM_PSC,
    input  logic [31:0] TIM_ARR,
    input  logic [31:0] TIM_CCR,
    output logic [31:0] TIM_IFR,
    input  logic [31:0] TIM_IER,
    input  logic [31:0] TIM_ICR,

    output logic pwm_out,
    output logic irq
);

    // Control bit decode
    // TIM_CR[0] : CEN
    // TIM_CR[1] : OPM
    // TIM_CR[2] : DIR
    // TIM_CR[3] : PWMEN
    logic CEN;
    logic OPM;
    logic DIR;
    logic PWMEN;

    assign CEN   = TIM_CR[0];
    assign OPM   = TIM_CR[1];
    assign DIR   = TIM_CR[2];
    assign PWMEN = TIM_CR[3];

    // Interrupt flags / enables
    // TIM_IFR[0] : UIF
    // TIM_IFR[1] : CCIF
    logic UIF;
    logic CCIF;

    logic UIE;
    logic CCIE;

    assign UIE  = TIM_IER[0];
    assign CCIE = TIM_IER[1];

    assign TIM_IFR = {30'd0, CCIF, UIF};

    assign irq = (UIF & UIE) | (CCIF & CCIE);

    logic cen_flag;
    logic cen_d;
    logic cen_rise;

    assign cen_rise = CEN & ~cen_d;

    logic [31:0] arr_last;

    assign arr_last = (TIM_ARR == 32'd0) ? 32'd0 : TIM_ARR - 32'd1;

    assign pwm_out = PWMEN && cen_flag && (TIM_CNT < TIM_CCR);

    logic [31:0] psc_cnt;
    logic        psc_tick;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            psc_cnt  <= 32'd0;
            psc_tick <= 1'b0;
        end else begin
            if (!cen_flag) begin
                psc_cnt  <= 32'd0;
                psc_tick <= 1'b0;
            end else if (psc_cnt >= TIM_PSC) begin
                psc_cnt  <= 32'd0;
                psc_tick <= 1'b1;
            end else begin
                psc_cnt  <= psc_cnt + 32'd1;
                psc_tick <= 1'b0;
            end
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cen_d    <= 1'b0;
            cen_flag <= 1'b0;
            TIM_CNT  <= 32'd0;
            UIF      <= 1'b0;
            CCIF     <= 1'b0;
        end else begin
            cen_d <= CEN; // synchronizer

            // Interrupt clear
            // TIM_ICR[0] = UIF clear
            // TIM_ICR[1] = CCIF clear
            if (TIM_ICR[0]) begin
                UIF <= 1'b0;
            end

            if (TIM_ICR[1]) begin
                CCIF <= 1'b0;
            end

            // Internal enable control
            // CEN = 0이면 stop
            // CEN rising edge에서 start
            // OPM이면 update event 후 cen_flag clear
            if (!CEN) begin
                cen_flag <= 1'b0;
            end else if (cen_rise) begin
                cen_flag <= 1'b1;

                // down counter 시작 시 0에서 바로 update 되는 것 방지
                if (DIR) begin
                    TIM_CNT <= arr_last;
                end
            end

            if (cen_flag && psc_tick) begin
                if (DIR == 1'b0) begin
                    // Up Count
                    if (TIM_CNT >= arr_last) begin
                        TIM_CNT <= 32'd0;
                        UIF     <= 1'b1;
                        if (TIM_CCR == 32'd0) begin
                            CCIF <= 1'b1;
                        end
                        if (OPM) begin
                            cen_flag <= 1'b0;
                        end
                    end else begin
                        TIM_CNT <= TIM_CNT + 32'd1;

                        if ((TIM_CNT + 32'd1) == TIM_CCR) begin
                            CCIF <= 1'b1;
                        end
                    end
                end else begin
                    // Down Count
                    if (TIM_CNT == 32'd0) begin
                        TIM_CNT <= arr_last;
                        UIF     <= 1'b1;
                        if (arr_last == TIM_CCR) begin
                            CCIF <= 1'b1;
                        end
                        if (OPM) begin
                            cen_flag <= 1'b0;
                        end
                    end else begin
                        TIM_CNT <= TIM_CNT - 32'd1;

                        if ((TIM_CNT - 32'd1) == TIM_CCR) begin
                            CCIF <= 1'b1;
                        end
                    end
                end
            end
        end
    end

endmodule