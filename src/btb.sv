// btb.sv — direct-mapped Branch Target Buffer. Tag match on PC, returns
// predicted target and a hit flag. Direction comes from gshare_predictor.
`default_nettype none

module btb #(
    parameter int unsigned IDX_BITS = 6,     // 64 entries — TT area-friendly
    parameter int unsigned TAG_BITS = 12
)(
    input  wire logic        clk,
    input  wire logic        rst,

    // lookup (IF)
    input  wire logic [31:0] pc_if,
    output logic             hit,
    output logic [31:0]      target,

    // update (EX resolve, taken branches / jumps only)
    input  wire logic        upd_valid,
    input  wire logic [31:0] upd_pc,
    input  wire logic [31:0] upd_target
);
    localparam int unsigned ENTRIES = 1 << IDX_BITS;

    logic                 valid_q [ENTRIES-1:0];
    logic [TAG_BITS-1:0]  tag_q   [ENTRIES-1:0];
    logic [31:0]          tgt_q   [ENTRIES-1:0];

    wire logic [IDX_BITS-1:0] li = pc_if[IDX_BITS+1:2];
    wire logic [TAG_BITS-1:0] lt = pc_if[IDX_BITS+2+:TAG_BITS];
    wire logic [IDX_BITS-1:0] ui = upd_pc[IDX_BITS+1:2];
    wire logic [TAG_BITS-1:0] ut = upd_pc[IDX_BITS+2+:TAG_BITS];

    assign hit    = valid_q[li] && (tag_q[li] == lt);
    assign target = tgt_q[li];

    always_ff @(posedge clk) begin
        if (rst) begin
            for (int i = 0; i < ENTRIES; i++) valid_q[i] <= 1'b0;
        end else if (upd_valid) begin
            valid_q[ui] <= 1'b1;
            tag_q[ui]   <= ut;
            tgt_q[ui]   <= upd_target;
        end
    end
endmodule : btb
