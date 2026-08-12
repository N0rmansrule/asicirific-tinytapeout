// spram.sv — single-port synchronous RAM with byte enables. Behavioral model
// for simulation and TT; swapped for an OpenRAM macro at SKY130 hardening.
`default_nettype none
module spram #(
    parameter int unsigned WORDS = 512,
    parameter int unsigned AW    = $clog2(WORDS)
)(
    input  wire logic          clk,
    input  wire logic [AW-1:0] addr,
    input  wire logic [31:0]   wdata,
    input  wire logic [3:0]    be,
    input  wire logic          we,
    output logic [31:0]        rdata
);
    logic [31:0] mem [0:WORDS-1];
    always_ff @(posedge clk) begin
        if (we) begin
            if (be[0]) mem[addr][7:0]   <= wdata[7:0];
            if (be[1]) mem[addr][15:8]  <= wdata[15:8];
            if (be[2]) mem[addr][23:16] <= wdata[23:16];
            if (be[3]) mem[addr][31:24] <= wdata[31:24];
        end
        rdata <= mem[addr];
    end
endmodule : spram
