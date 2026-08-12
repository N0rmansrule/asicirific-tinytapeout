// reg_file.sv — 32 x 32-bit, 2 read ports, 1 write port, x0 hardwired to zero.
// Synchronous write, combinational read with same-cycle write-through bypass
// (needed by the six-stage pipeline's WB→ID path).
`default_nettype none

module reg_file (
    input  wire logic        clk,
    input  wire logic        we,
    input  wire logic [4:0]  waddr,
    input  wire logic [31:0] wdata,
    input  wire logic [4:0]  raddr1,
    input  wire logic [4:0]  raddr2,
    output logic [31:0]      rdata1,
    output logic [31:0]      rdata2
);

    logic [31:0] regs [31:0];

    always_ff @(posedge clk) begin
        if (we && (waddr != 5'd0))
            regs[waddr] <= wdata;
    end

    // read with write-through bypass; x0 always reads zero
    always_comb begin
        rdata1 = (raddr1 == 5'd0) ? 32'd0 :
                 (we && (waddr == raddr1)) ? wdata : regs[raddr1];
        rdata2 = (raddr2 == 5'd0) ? 32'd0 :
                 (we && (waddr == raddr2)) ? wdata : regs[raddr2];
    end

endmodule : reg_file
