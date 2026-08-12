// bp_top.sv — branch prediction wrapper. Swap predictor implementations here
// without touching the core. Combines GShare direction + BTB target + RAS.
`default_nettype none

module bp_top #(
    parameter int unsigned HIST_BITS = 8,
    parameter int unsigned IDX_BITS  = 10,
    parameter int unsigned BTB_IDX   = 6
)(
    input  wire logic        clk,
    input  wire logic        rst,

    // IF-stage query
    input  wire logic [31:0] pc_if,
    output logic             pred_taken,
    output logic [31:0]      pred_target,

    // EX-stage resolve
    input  wire logic        upd_valid,      // resolved branch or jump
    input  wire logic [31:0] upd_pc,
    input  wire logic        upd_taken,
    input  wire logic [31:0] upd_target,

    // RAS hints from decode
    input  wire logic        ras_push,
    input  wire logic [31:0] ras_push_addr,
    input  wire logic        ras_pop
);
    logic dir_taken, btb_hit;
    logic [31:0] btb_target, ras_addr;
    logic ras_valid;

    gshare_predictor #(.HIST_BITS(HIST_BITS), .IDX_BITS(IDX_BITS)) u_gshare (
        .clk(clk), .rst(rst),
        .pc_if(pc_if), .pred_taken(dir_taken),
        .upd_valid(upd_valid), .upd_pc(upd_pc), .upd_taken(upd_taken)
    );

    btb #(.IDX_BITS(BTB_IDX)) u_btb (
        .clk(clk), .rst(rst),
        .pc_if(pc_if), .hit(btb_hit), .target(btb_target),
        .upd_valid(upd_valid && upd_taken), .upd_pc(upd_pc), .upd_target(upd_target)
    );

    ras u_ras (
        .clk(clk), .rst(rst),
        .push(ras_push), .push_addr(ras_push_addr), .pop(ras_pop),
        .top_addr(ras_addr), .top_valid(ras_valid)
    );

    // predict taken only when we also know where to go
    assign pred_taken  = dir_taken && btb_hit;
    assign pred_target = (ras_pop && ras_valid) ? ras_addr : btb_target;
endmodule : bp_top
