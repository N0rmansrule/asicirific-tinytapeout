// branch_comp.sv — branch decision for the RV32 conditional branches.
// Given the funct3 field and the three comparison results from the subtract in
// the core (equal/zero, signed less-than, unsigned less-than), it decides
// whether the branch is taken. Pure combinational, so it is trivial to test
// exhaustively against a truth table.
`default_nettype none

module branch_comp (
    input  wire logic [2:0] funct3,
    input  wire logic       zero,          // rs1 == rs2
    input  wire logic       lt_signed,     // rs1 <  rs2  (signed)
    input  wire logic       lt_unsigned,   // rs1 <  rs2  (unsigned)
    output logic            taken
);
    always_comb begin
        unique case (funct3)
            3'b000:  taken =  zero;         // beq
            3'b001:  taken = ~zero;         // bne
            3'b100:  taken =  lt_signed;    // blt
            3'b101:  taken = ~lt_signed;    // bge
            3'b110:  taken =  lt_unsigned;  // bltu
            3'b111:  taken = ~lt_unsigned;  // bgeu
            default: taken = 1'b0;
        endcase
    end
endmodule : branch_comp
