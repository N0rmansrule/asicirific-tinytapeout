// load_unit.sv — align and extend loaded data per funct3 (LB/LH/LW/LBU/LHU).
`default_nettype none

module load_unit (
    input  wire logic [31:0] rdata,
    input  wire logic [1:0]  addr_lo,
    input  wire logic [2:0]  funct3,
    output logic [31:0]      out
);
    logic [7:0]  b;
    logic [15:0] h;
    always_comb begin
        b = rdata[8*addr_lo +: 8];
        h = addr_lo[1] ? rdata[31:16] : rdata[15:0];
        unique case (funct3)
            3'b000: out = {{24{b[7]}},  b};   // LB
            3'b001: out = {{16{h[15]}}, h};   // LH
            3'b010: out = rdata;              // LW
            3'b100: out = {24'd0, b};         // LBU
            3'b101: out = {16'd0, h};         // LHU
            default: out = rdata;
        endcase
    end
endmodule : load_unit
