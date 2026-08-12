// gshare_predictor.sv — GShare direction predictor (from the ASICirific 151 core).
// PC XOR global-history indexes a table of 2-bit saturating counters.
// Direction only; the BTB (btb.sv) supplies targets. Swap the whole predictor
// by replacing this file behind bp_top.sv.
`default_nettype none

module gshare_predictor #(
    parameter int unsigned HIST_BITS = 8,           // global history length
    parameter int unsigned IDX_BITS  = 10           // 1024-entry pattern table
)(
    input  wire logic        clk,
    input  wire logic        rst,

    // predict port (IF stage)
    input  wire logic [31:0] pc_if,
    output logic             pred_taken,

    // update port (from EX resolve)
    input  wire logic        upd_valid,
    input  wire logic [31:0] upd_pc,
    input  wire logic        upd_taken
);

    localparam int unsigned ENTRIES = 1 << IDX_BITS;

    logic [1:0]            pht [ENTRIES-1:0];       // 2-bit counters
    logic [HIST_BITS-1:0]  ghr;                     // global history register

    // index = pc[.. :2] XOR history (zero-extended into index width)
    function automatic logic [IDX_BITS-1:0] idx_of (
        input logic [31:0]          pc,
        input logic [HIST_BITS-1:0] hist
    );
        logic [IDX_BITS-1:0] pc_part;
        logic [IDX_BITS-1:0] h_part;
        begin
            pc_part = pc[IDX_BITS+1:2];
            h_part  = {{(IDX_BITS-HIST_BITS){1'b0}}, hist};
            idx_of  = pc_part ^ h_part;
        end
    endfunction

    // prediction: MSB of the counter
    assign pred_taken = pht[idx_of(pc_if, ghr)][1];

    // update: saturating counter + shift history
    always_ff @(posedge clk) begin
        if (rst) begin
            ghr <= '0;
            for (int i = 0; i < ENTRIES; i++) pht[i] <= 2'b01; // weakly not-taken
        end else if (upd_valid) begin
            logic [IDX_BITS-1:0] ui;
            ui = idx_of(upd_pc, ghr);
            if (upd_taken  && pht[ui] != 2'b11) pht[ui] <= pht[ui] + 2'd1;
            if (!upd_taken && pht[ui] != 2'b00) pht[ui] <= pht[ui] - 2'd1;
            ghr <= {ghr[HIST_BITS-2:0], upd_taken};
        end
    end

endmodule : gshare_predictor
