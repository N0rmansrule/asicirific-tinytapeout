// riscv_dtm.sv — RISC-V Debug Transport Module (spec 0.13.2).
// Implements the DTMCS and DMI JTAG data registers behind jtag_tap.sv and
// converts DMI writes/reads into request/response transactions toward
// riscv_dm. NOTE: v1 assumes tck and the DM clock are synchronous (TT ties
// them appropriately); async handshake CDC arrives with Phase 8 clock work.
`default_nettype none

module riscv_dtm #(
    parameter int unsigned ABITS = 7
)(
    input  wire logic tck,
    input  wire logic trst_n,

    // from jtag_tap
    input  wire logic dmi_capture,
    input  wire logic dmi_shift,
    input  wire logic dmi_update,
    input  wire logic dmi_tdi,
    output logic      dmi_tdo,
    input  wire logic sel_dtmcs,      // ir == DTMCS
    input  wire logic sel_dmi,        // ir == DMI

    // DMI request toward riscv_dm
    output logic                 req_valid,
    output logic [ABITS-1:0]     req_addr,
    output logic [31:0]          req_wdata,
    output logic [1:0]           req_op,      // 1=read 2=write
    input  wire logic            rsp_valid,
    input  wire logic [31:0]     rsp_rdata,
    input  wire logic [1:0]      rsp_status   // 0=ok
);
    localparam int unsigned DMI_BITS = ABITS + 32 + 2;

    // DTMCS: [3:0] version=1, [9:4] abits, [11:10] dmistat, [14:12] idle
    wire logic [31:0] dtmcs_val = {17'd0, 3'd1, 2'b00, ABITS[5:0], 4'd1};

    logic [31:0]         dtmcs_shift;
    logic [DMI_BITS-1:0] dmi_shift_q;
    logic [31:0]         cap_rdata;
    logic [1:0]          cap_status;

    // capture response for next DMI read-out
    always_ff @(posedge tck or negedge trst_n) begin
        if (!trst_n) begin
            cap_rdata <= 32'd0; cap_status <= 2'd0;
        end else if (rsp_valid) begin
            cap_rdata <= rsp_rdata; cap_status <= rsp_status;
        end
    end

    always_ff @(posedge tck) begin
        if (dmi_capture) begin
            dtmcs_shift <= dtmcs_val;
            dmi_shift_q <= {{ABITS{1'b0}}, cap_rdata, cap_status};
        end else if (dmi_shift) begin
            dtmcs_shift <= {dmi_tdi, dtmcs_shift[31:1]};
            dmi_shift_q <= {dmi_tdi, dmi_shift_q[DMI_BITS-1:1]};
        end
    end

    assign dmi_tdo = sel_dtmcs ? dtmcs_shift[0] : dmi_shift_q[0];

    // launch request on update
    always_ff @(posedge tck or negedge trst_n) begin
        if (!trst_n) begin
            req_valid <= 1'b0;
        end else begin
            req_valid <= 1'b0;
            if (dmi_update && sel_dmi) begin
                req_addr  <= dmi_shift_q[DMI_BITS-1 -: ABITS];
                req_wdata <= dmi_shift_q[33:2];
                req_op    <= dmi_shift_q[1:0];
                req_valid <= (dmi_shift_q[1:0] != 2'b00);
            end
        end
    end
endmodule : riscv_dtm
