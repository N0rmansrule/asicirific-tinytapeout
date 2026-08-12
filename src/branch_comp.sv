// branch_comp.sv — branch comparator producing eq / signed-lt / unsigned-lt.
// The branch control unit turns these into taken/not-taken per funct3.
`default_nettype none

module branch_comp
    import asicirific_pkg::*;
(
    input  wire logic [31:0] rs1,
    input  wire logic [31:0] rs2,
    output br_cmp_t          cmp
);

    always_comb begin
        cmp.eq  = (rs1 == rs2);
        cmp.lt  = ($signed(rs1) < $signed(rs2));
        cmp.ltu = (rs1 < rs2);
    end

endmodule : branch_comp
