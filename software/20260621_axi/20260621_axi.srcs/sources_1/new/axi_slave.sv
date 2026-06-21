`timescale 1ns / 1ps

module axi_slave (
    input logic ACLK,
    input logic ARESETn,

    input  logic [31:0] AWADDR,
    input  logic        AWVALID,
    output logic        AWREADY,

    input  logic [31:0] WDATA,
    input  logic        WVALID,
    output logic        WREADY,

    output logic [1:0] BRESP,
    output logic       BVALID,
    input  logic       BREADY,

    input  logic [31:0] ARADDR,
    input  logic        ARVALID,
    output logic        ARREADY,

    output logic [31:0] RDATA,
    output logic        RVALID,
    input  logic        RREADY,
    output logic [ 1:0] RRESP
);

  logic [31:0] slv_reg0, slv_reg1, slv_reg2, slv_reg3;
  logic [31:0] addr_r;
  logic [31:0] araddr;

  // ============================================================
  // AW Channel
  // ============================================================
  typedef enum logic {
    AW_IDLE  = 0,
    AW_READY
  } aw_state_e;

  aw_state_e aw_state, aw_state_next;

  always_ff @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) begin
      aw_state <= AW_IDLE;
    end else begin
      aw_state <= aw_state_next;
    end
  end

  always_comb begin
    aw_state_next = aw_state;
    AWREADY       = 1'b0;

    case (aw_state)
      AW_IDLE: begin
        AWREADY = 1'b0;
        if (AWVALID) begin
          aw_state_next = AW_READY;
        end
      end

      AW_READY: begin
        AWREADY       = 1'b1;
        aw_state_next = AW_IDLE;
      end

      default: begin
        AWREADY       = 1'b0;
        aw_state_next = AW_IDLE;
      end
    endcase
  end

  // Write address latch
  always_ff @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) begin
      addr_r <= 32'd0;
    end else begin
      if (AWVALID && AWREADY) begin
        addr_r <= AWADDR;
      end
    end
  end

  // ============================================================
  // W Channel
  // ============================================================
  typedef enum logic {
    W_IDLE  = 0,
    W_READY
  } w_state_e;

  w_state_e w_state, w_state_next;

  always_ff @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) begin
      w_state <= W_IDLE;
    end else begin
      w_state <= w_state_next;
    end
  end

  always_comb begin
    w_state_next = w_state;
    WREADY       = 1'b0;

    case (w_state)
      W_IDLE: begin
        WREADY = 1'b0;
        if (WVALID && AWVALID && AWREADY) begin
          w_state_next = W_READY;
        end
      end

      W_READY: begin
        WREADY       = 1'b1;
        w_state_next = W_IDLE;
      end

      default: begin
        WREADY       = 1'b0;
        w_state_next = W_IDLE;
      end
    endcase
  end

  // Register write sequential logic
  always_ff @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) begin
      slv_reg0 <= 32'd0;
      slv_reg1 <= 32'd0;
      slv_reg2 <= 32'd0;
      slv_reg3 <= 32'd0;
    end else begin
      if (WVALID && WREADY) begin
        case (addr_r[3:2])
          2'd0: slv_reg0 <= WDATA;
          2'd1: slv_reg1 <= WDATA;
          2'd2: slv_reg2 <= WDATA;
          2'd3: slv_reg3 <= WDATA;
          default: begin
          end
        endcase
      end
    end
  end

  // ============================================================
  // B Channel
  // ============================================================
  typedef enum logic {
    B_IDLE,
    B_VALID
  } b_state_e;

  b_state_e b_state, b_state_next;

  always_ff @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) begin
      b_state <= B_IDLE;
    end else begin
      b_state <= b_state_next;
    end
  end

  always_comb begin
    b_state_next = b_state;
    BVALID       = 1'b0;
    BRESP        = 2'b00;

    case (b_state)
      B_IDLE: begin
        BVALID = 1'b0;
        BRESP  = 2'b00;

        if (WVALID && WREADY) begin
          b_state_next = B_VALID;
        end
      end

      B_VALID: begin
        BVALID = 1'b1;
        BRESP  = 2'b00;

        if (BREADY) begin
          b_state_next = B_IDLE;
        end
      end

      default: begin
        BVALID       = 1'b0;
        BRESP        = 2'b00;
        b_state_next = B_IDLE;
      end
    endcase
  end

  // ============================================================
  // AR Channel
  // ============================================================
  typedef enum logic {
    AR_IDLE  = 0,
    AR_READY
  } ar_state_e;

  ar_state_e ar_state, ar_state_next;

  always_ff @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) begin
      ar_state <= AR_IDLE;
    end else begin
      ar_state <= ar_state_next;
    end
  end

  always_comb begin
    ar_state_next = ar_state;
    ARREADY       = 1'b0;

    case (ar_state)
      AR_IDLE: begin
        ARREADY = 1'b0;

        if (ARVALID) begin
          ar_state_next = AR_READY;
        end
      end

      AR_READY: begin
        ARREADY       = 1'b1;
        ar_state_next = AR_IDLE;
      end

      default: begin
        ARREADY       = 1'b0;
        ar_state_next = AR_IDLE;
      end
    endcase
  end

  // Read address latch
  always_ff @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) begin
      araddr <= 32'd0;
    end else begin
      if (ARVALID && ARREADY) begin
        araddr <= ARADDR;
      end
    end
  end

  // ============================================================
  // R Channel
  // ============================================================
  typedef enum logic {
    R_IDLE,
    R_VALID
  } r_state_e;

  r_state_e r_state, r_state_next;

  always_ff @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) begin
      r_state <= R_IDLE;
    end else begin
      r_state <= r_state_next;
    end
  end

  always_comb begin
    r_state_next = r_state;
    RVALID       = 1'b0;
    RRESP        = 2'b00;

    case (r_state)
      R_IDLE: begin
        RVALID = 1'b0;
        RRESP  = 2'b00;

        if (ARVALID && ARREADY) begin
          r_state_next = R_VALID;
        end
      end

      R_VALID: begin
        RVALID = 1'b1;
        RRESP  = 2'b00;

        if (RREADY && RVALID) begin
          r_state_next = R_IDLE;
        end
      end

      default: begin
        RVALID       = 1'b0;
        RRESP        = 2'b00;
        r_state_next = R_IDLE;
      end
    endcase
  end

  // RDATA sequential latch
  always_ff @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) begin
      RDATA <= 32'd0;
    end else begin
      if (ARVALID && ARREADY) begin
        case (ARADDR[3:2])
          2'd0: RDATA <= slv_reg0;
          2'd1: RDATA <= slv_reg1;
          2'd2: RDATA <= slv_reg2;
          2'd3: RDATA <= slv_reg3;
          default: RDATA <= 32'd0;
        endcase
      end
    end
  end

endmodule