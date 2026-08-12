// imm_gen.sv — RV32 immediate generator for I/S/B/U/J formats.
`default_nettype none

import asicirific_pkg::*;
module imm_gen (
    input  wire logic [31:0] inst,
    input  wire imm_sel_t    sel,
    output logic [31:0]      imm
);

    always_comb begin
        unique case (sel)
            IMM_I: imm = {{21{inst[31]}}, inst[30:20]};
            IMM_S: imm = {{21{inst[31]}}, inst[30:25], inst[11:7]};
            IMM_B: imm = {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};
            IMM_U: imm = {inst[31:12], 12'd0};
            IMM_J: imm = {{12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0};
            default: imm = 32'd0;
        endcase
    end

endmodule : imm_gen
