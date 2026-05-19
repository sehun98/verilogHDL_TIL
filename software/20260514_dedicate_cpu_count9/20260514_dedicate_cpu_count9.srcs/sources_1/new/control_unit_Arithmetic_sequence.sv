`timescale 1ns / 1ps

module control_unit_Arithmetic_sequence (
    input  logic clk,
    input  logic rst_n,
    output logic A_src_sel,
    output logic SUM_src_sel,
    output logic ALU_src_sel,
    output logic A_reg_load,
    output logic SUM_reg_load,
    output logic OUT_reg_load,
    input  logic A_gr_10
);

    typedef enum logic [2:0] {
        S0,
        S1,
        S2,
        S3,
        S4,
        S5
    } state_t;

    state_t state, n_state;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S0;
        end else begin
            state <= n_state;
        end
    end

    always_comb begin
        n_state = state;
        A_src_sel = 0;
        SUM_src_sel = 0;
        A_reg_load = 0;
        ALU_src_sel = 0;
        SUM_reg_load = 0;
        OUT_reg_load = 0;
        case (state)
            S0: begin
                A_src_sel = 0;
                SUM_src_sel = 0;
                ALU_src_sel = 0;
                A_reg_load = 1;
                SUM_reg_load = 1;
                OUT_reg_load = 0;
                n_state = S1;
            end
            S1: begin
                A_src_sel = 0;
                SUM_src_sel = 0;
                ALU_src_sel = 0;
                A_reg_load = 0;
                SUM_reg_load = 0;
                OUT_reg_load = 0;
                if (A_gr_10) begin
                    n_state = S5;
                end else begin
                    n_state = S2;
                end
            end
            S2: begin
                A_src_sel = 0;
                SUM_src_sel = 0;
                ALU_src_sel = 0;
                A_reg_load = 0;
                SUM_reg_load = 0;
                OUT_reg_load = 1;
                n_state = S3;
            end
            S3: begin
                A_src_sel = 1;
                SUM_src_sel = 0;
                ALU_src_sel = 0;
                A_reg_load = 1;
                SUM_reg_load = 0;
                OUT_reg_load = 0;
                n_state = S4;
            end
            S4: begin
                A_src_sel = 0;
                SUM_src_sel = 1;
                ALU_src_sel = 1;
                A_reg_load = 0;
                SUM_reg_load = 1;
                OUT_reg_load = 0;
                n_state = S1;
            end
            S5: begin
                A_src_sel = 0;
                SUM_src_sel = 0;
                ALU_src_sel = 0;
                A_reg_load = 0;
                SUM_reg_load = 0;
                OUT_reg_load = 1;
            end
        endcase
    end
endmodule