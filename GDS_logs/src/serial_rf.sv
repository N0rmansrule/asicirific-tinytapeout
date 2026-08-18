// serial_rf.sv — shift-register register file for the bit-serial core (RV32E).
// Sixteen 32-bit registers, all rotating one bit per clock so that each one
// presents its bits LSB first at a read tap. Two read taps (rs1, rs2) and one
// write path (rd) that shifts the ALU result bit in at the top while the rest
// recirculate. x0 always reads zero and is never written. This avoids the wide
// read multiplexers of a parallel register file, which is what keeps the area
// down: the storage is unavoidable, but the access logic is a few 1-bit muxes.
`default_nettype none

module serial_rf (
    input  wire logic       clk,
    input  wire logic       rst,
    input  wire logic       en,       // rotate all registers one bit
    input  wire logic [3:0] rs1,
    input  wire logic [3:0] rs2,
    input  wire logic [3:0] rd,
    input  wire logic       we,       // shift wbit into rd instead of recirculating
    input  wire logic       wbit,
    input  wire logic       shl,      // shift rd left by 1 (others hold)
    input  wire logic       shr,      // shift rd right by 1, inject shin at MSB
    input  wire logic       shin,     // bit injected at MSB on a right shift
    output logic            rs1_bit,
    output logic            rs2_bit,
    output logic            rd_msb    // top bit of rd, for arithmetic right shift
);
    logic [31:0] sr [15:0];

    assign rs1_bit = (rs1 == 4'd0) ? 1'b0 : sr[rs1][0];
    assign rs2_bit = (rs2 == 4'd0) ? 1'b0 : sr[rs2][0];
    assign rd_msb  = sr[rd][31];

    integer i;
    always_ff @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < 16; i = i + 1) sr[i] <= 32'd0;
        end else if (shl || shr) begin
            // shift only rd; the other registers hold so their alignment is kept
            if (rd != 4'd0) begin
                if (shr) sr[rd] <= {shin, sr[rd][31:1]};   // right, inject at MSB
                else     sr[rd] <= {sr[rd][30:0], 1'b0};   // left, zero at LSB
            end
        end else if (en) begin
            for (i = 0; i < 16; i = i + 1) begin
                if (we && (rd != 4'd0) && (i == rd))
                    sr[i] <= {wbit, sr[i][31:1]};        // shift in the new bit
                else
                    sr[i] <= {sr[i][0], sr[i][31:1]};    // recirculate
            end
        end
    end
endmodule : serial_rf
