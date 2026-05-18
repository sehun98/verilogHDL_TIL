`timescale 1ns / 1ps

module control_unit (
    input  logic clk,
    input  logic rst_n,
    input  logic a_eq_9,
    output logic a_src_sel,
    output logic a_reg_load,
    output logic a_out_sel
);

    typedef enum logic [1:0] {
        S0 = 0,
        S1,
        S2
    } state_t;

    state_t state;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S0;
            a_src_sel <= 0;
            a_reg_load <= 0;
            a_out_sel <= 0;
        end else begin
        case (state)
            S0: begin
                state <= S1;
                a_src_sel <= 0;
                a_reg_load <= 1;
                a_out_sel <= 0;
            end
            S1: begin
                if (a_eq_9) begin
                    state <= S2;
                    a_src_sel  <= 0;
                    a_reg_load <= 0;
                    a_out_sel  <= 1; // ***** mealy 방식
                end else begin
                    state <= S1;
                    a_src_sel  <= 1;
                    a_reg_load <= 1;
                    a_out_sel  <= 0;
                end
            end
            S2: begin
                a_src_sel  <= 0;
                a_reg_load <= 0;
                a_out_sel  <= 1; // ***** mealy 방식
                //a_out_sel  <= 0;
                //state <= S0;
            end
        endcase
        end
    end

endmodule
