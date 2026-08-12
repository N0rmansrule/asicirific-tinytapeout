// alu.sv — single shared adder/subtractor ALU (from the ASICirific EECS 151 core)
// ADD, SUB, SLT, SLTU all reuse one 33-bit adder to shorten the critical path.
`default_nettype none

import asicirific_pkg::*;
module alu (
    input  wire  logic [31:0] a,
    input  wire  logic [31:0] b,
    input  wire  alu_op_t     op,
    output logic [31:0]       y
);

    logic        sub_mode;
    logic [32:0] addsub;      // 33 bits: bit 32 is carry-out for unsigned compare
    logic [4:0]  shamt;
    logic        slt_bit, sltu_bit;

    always_comb begin
        shamt    = b[4:0];
        sub_mode = (op == ALU_SUB) || (op == ALU_SLT) || (op == ALU_SLTU);
        addsub   = {1'b0, a} + {1'b0, (sub_mode ? ~b : b)} + {32'd0, sub_mode};

        // signed less-than: if signs differ, a's sign decides (overflow-safe)
        slt_bit  = (a[31] != b[31]) ? a[31] : addsub[31];
        // unsigned less-than: borrow means carry-out is 0
        sltu_bit = ~addsub[32];

        unique case (op)
            ALU_ADD:     y = addsub[31:0];
            ALU_SUB:     y = addsub[31:0];
            ALU_AND:     y = a & b;
            ALU_OR:      y = a | b;
            ALU_XOR:     y = a ^ b;
            ALU_SLT:     y = {31'd0, slt_bit};
            ALU_SLTU:    y = {31'd0, sltu_bit};
            ALU_SLL:     y = a << shamt;
            ALU_SRL:     y = a >> shamt;
            ALU_SRA:     y = $signed(a) >>> shamt;
            ALU_COPY_B:  y = b;
            ALU_CSR_CLR: y = a & ~b;
            default:     y = 32'd0;
        endcase
    end

endmodule : alu
