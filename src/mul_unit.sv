// mul_unit.sv — RV32M multiply. Combinational 32x32->64 for now; if timing
// at 125 MHz complains in synthesis, pipeline to 2 stages (noted in plan).
`default_nettype none

module mul_unit (
    input  wire logic [31:0] a,
    input  wire logic [31:0] b,
    input  wire logic [2:0]  funct3,   // 000 MUL, 001 MULH, 010 MULHSU, 011 MULHU
    output logic [31:0]      y
);
    logic signed [63:0] ss;
    logic signed [63:0] su;
    logic        [63:0] uu;
    always_comb begin
        ss = $signed(a) * $signed(b);
        su = $signed(a) * $signed({1'b0, b});
        uu = a * b;
        case (funct3[1:0])
            2'b00: y = ss[31:0];    // MUL
            2'b01: y = ss[63:32];   // MULH
            2'b10: y = su[63:32];   // MULHSU
            2'b11: y = uu[63:32];   // MULHU
            default: y = 32'd0;
        endcase
    end
endmodule : mul_unit
