`timescale 1ns / 1ps

module control_unit (
    input  logic clk,
    input  logic rst_n,
    output logic src_sel,
    output logic load,
    output logic out_sel,
    input  logic eq_out
);

    typedef enum logic [1:0] {
        IDLE,
        DATA,
        DONE
    } state_t;

    state_t state;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            src_sel <= 1'b0;
            load <= 1'b0;
            out_sel <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    src_sel <= 1'b0;
                    load <= 1'b1;
                    out_sel <= 1'b0;
                    state <= DATA;
                end
                DATA: begin
                    src_sel <= 1'b1;
                    load <= 1'b1;
                    out_sel <= 1'b0;

                    if (eq_out) begin
                        state <= DONE;
                        src_sel <= 1'b0;
                        load <= 1'b0;
                        out_sel <= 1'b1;
                    end
                end
                DONE: begin
                    src_sel <= 1'b0;
                    load <= 1'b0;
                    out_sel <= 1'b1;
                end
            endcase
        end
    end
endmodule
