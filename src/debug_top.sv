// debug_top.sv — glues jtag_tap + riscv_dtm + riscv_dm into one drop-in block.
`default_nettype none

module debug_top (
    // JTAG pins
    input  wire logic tck,
    input  wire logic tms,
    input  wire logic tdi,
    input  wire logic trst_n,
    output logic      tdo,
    output logic      tdo_oe,

    // system side (DM runs on tck in v1; see riscv_dtm CDC note)
    output logic        halt_req,
    input  wire logic   halted,
    output logic        sb_re,
    output logic        sb_we,
    output logic [31:0] sb_addr,
    output logic [31:0] sb_wdata,
    input  wire logic [31:0] sb_rdata
);
    logic dmi_capture, dmi_shift, dmi_update, dmi_tdi_w, dmi_tdo_w;
    logic req_valid;
    logic [6:0]  req_addr;
    logic [31:0] req_wdata;
    logic [1:0]  req_op;
    logic rsp_valid;
    logic [31:0] rsp_rdata;
    logic [1:0]  rsp_status;

    jtag_tap u_tap (
        .tck(tck), .tms(tms), .tdi(tdi), .trst_n(trst_n),
        .tdo(tdo), .tdo_oe(tdo_oe),
        .dmi_capture(dmi_capture), .dmi_shift(dmi_shift),
        .dmi_update(dmi_update), .dmi_tdi(dmi_tdi_w), .dmi_tdo(dmi_tdo_w)
    );

    // which user DR is selected
    wire logic sel_dtmcs = (u_tap.ir == 5'h10);
    wire logic sel_dmi   = (u_tap.ir == 5'h11);

    riscv_dtm u_dtm (
        .tck(tck), .trst_n(trst_n),
        .dmi_capture(dmi_capture), .dmi_shift(dmi_shift), .dmi_update(dmi_update),
        .dmi_tdi(dmi_tdi_w), .dmi_tdo(dmi_tdo_w),
        .sel_dtmcs(sel_dtmcs), .sel_dmi(sel_dmi),
        .req_valid(req_valid), .req_addr(req_addr), .req_wdata(req_wdata),
        .req_op(req_op),
        .rsp_valid(rsp_valid), .rsp_rdata(rsp_rdata), .rsp_status(rsp_status)
    );

    riscv_dm u_dm (
        .clk(tck), .rst(~trst_n),
        .req_valid(req_valid), .req_addr(req_addr), .req_wdata(req_wdata),
        .req_op(req_op),
        .rsp_valid(rsp_valid), .rsp_rdata(rsp_rdata), .rsp_status(rsp_status),
        .halt_req(halt_req), .halted(halted),
        .sb_re(sb_re), .sb_we(sb_we), .sb_addr(sb_addr), .sb_wdata(sb_wdata),
        .sb_rdata(sb_rdata)
    );
endmodule : debug_top
