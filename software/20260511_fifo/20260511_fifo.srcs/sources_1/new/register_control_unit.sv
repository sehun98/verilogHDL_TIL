`timescale 1ns / 1ps

module register_control_unit (
    input  logic       clk,
    input  logic       rst_n,

    input  logic       push,
    input  logic       pop,

    output logic [3:0] wptr,
    output logic [3:0] rptr,
    output logic       full,
    output logic       empty
);

    // 1. 초기조건
    // 2. push only
    // 3. pop only
    // 4. push/pop
    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            wptr <= 4'd0;
            rptr <= 4'd0;
            full <= 1'd0;
            empty <= 1'b1;
        end else begin
            wptr <= wptr;
            rptr <= rptr;
            full <= full;
            empty <= empty;
            case({push,pop})
                2'b01 : begin
                    if(!empty) begin
                        rptr <= rptr + 1'b1;
                        full <= 1'b0;
                        if(wptr==rptr+1) empty <= 1'b1;
                    end
                end
                2'b10 : begin
                    if(!full) begin
                        wptr <= wptr + 1'b1;
                        empty <= 1'b0;
                        if(wptr+1==rptr) full <= 1'b1;
                    end
                end
                2'b11 : begin
                    if(full) begin
                        rptr <= rptr + 1'b1;
                        full <= 1'b0;
                    end else if(empty) begin
                        wptr <= wptr + 1'b1;
                        empty <= 1'b0;
                    end else begin
                        rptr <= rptr + 1'b1;
                        wptr <= wptr + 1'b1;
                    end
                end
            endcase
        end
    end
endmodule

