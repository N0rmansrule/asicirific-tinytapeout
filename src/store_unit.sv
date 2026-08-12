// store_unit.sv — byte-enable and write-data alignment for SB/SH/SW.
`default_nettype none

module store_unit (
    input  wire logic [31:0] wdata_in,
    input  wire logic [1:0]  addr_lo,
    input  wire logic [2:0]  funct3,
    output logic [31:0]      wdata_out,
    output logic [3:0]       be
);
    always_comb begin
        unique case (funct3[1:0])
            2'b00: begin // SB
                wdata_out = {4{wdata_in[7:0]}};
                be = 4'b0001 << addr_lo;
            end
            2'b01: begin // SH
                wdata_out = {2{wdata_in[15:0]}};
                be = addr_lo[1] ? 4'b1100 : 4'b0011;
            end
            default: begin // SW
                wdata_out = wdata_in;
                be = 4'b1111;
            end
        endcase
    end
endmodule : store_unit
