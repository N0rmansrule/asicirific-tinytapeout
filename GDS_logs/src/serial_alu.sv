// serial_alu.sv — one-bit-at-a-time ALU for the bit-serial core.
// Processes operands LSB first, one bit per clock, holding the add/subtract
// carry in a single flop across the 32-bit pass. `init` loads the starting
// carry (0 for add, 1 for subtract) at the first bit. Logic ops are bitwise.
// SLT/SLTU fall out of the subtract: the sign of a-b, corrected for overflow.
`default_nettype none

module serial_alu
    import asicirific_pkg::*;
(
    input  wire logic    clk,
    input  wire logic    rst,
    input  wire logic    init,     // pulse on the first (LSB) bit
    input  wire logic    en,       // advance one bit this cycle
    input  wire alu_op_t op,
    input  wire logic    a,        // rs1 bit
    input  wire logic    b,        // rs2 (or immediate) bit
    output logic         y,        // result bit
    output logic         last_cout // carry/borrow out after the final bit
);
    wire sub  = (op == ALU_SUB) || (op == ALU_SLT) || (op == ALU_SLTU);
    wire bb   = sub ? ~b : b;      // subtract by adding the ones complement
    logic carry;

    // on the first (LSB) bit the running carry has not been loaded yet, so use
    // the subtract preset directly; afterwards use the carry flop.
    wire cin  = init ? (sub ? 1'b1 : 1'b0) : carry;
    wire sum  = a ^ bb ^ cin;
    wire cout = (a & bb) | (a & cin) | (bb & cin);

    always_comb begin
        unique case (op)
            ALU_AND:  y = a & b;
            ALU_OR:   y = a | b;
            ALU_XOR:  y = a ^ b;
            default:  y = sum;      // add/sub (slt handled by the caller via cout/sign)
        endcase
    end

    assign last_cout = cout;

    always_ff @(posedge clk) begin
        if (rst)     carry <= 1'b0;
        else if (en) carry <= cout;
    end
endmodule : serial_alu
