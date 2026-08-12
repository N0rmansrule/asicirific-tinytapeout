// csr_file.sv — minimal machine-mode CSRs: mstatus, mtvec, mepc, mcause,
// mscratch, mie, mip, mcycle(h), minstret(h). Read+modify happen in X stage.
// Trap entry/exit sequencing arrives with the trap unit (Phase 2b).
`default_nettype none

module csr_file
    import asicirific_pkg::*;
(
    input  wire logic        clk,
    input  wire logic        rst,

    // access from X stage (CSRRW/S/C [I])
    input  wire logic        en,
    input  wire logic [11:0] addr,
    input  wire logic [2:0]  funct3,
    input  wire logic [31:0] wval,      // rs1 value or zimm
    output logic [31:0]      rval,

    input  wire logic        instret_pulse
);
    localparam logic [11:0] A_MSTATUS  = 12'h300;
    localparam logic [11:0] A_MIE      = 12'h304;
    localparam logic [11:0] A_MTVEC    = 12'h305;
    localparam logic [11:0] A_MSCRATCH = 12'h340;
    localparam logic [11:0] A_MEPC     = 12'h341;
    localparam logic [11:0] A_MCAUSE   = 12'h342;
    localparam logic [11:0] A_MIP      = 12'h344;
    localparam logic [11:0] A_MCYCLE   = 12'hB00;
    localparam logic [11:0] A_MCYCLEH  = 12'hB80;
    localparam logic [11:0] A_MINSTRET = 12'hB02;
    localparam logic [11:0] A_MINSTRETH= 12'hB82;

    logic [31:0] mstatus_q, mie_q, mtvec_q, mscratch_q, mepc_q, mcause_q, mip_q;
    logic [63:0] mcycle_q, minstret_q;

    always_comb begin
        unique case (addr)
            A_MSTATUS:   rval = mstatus_q;
            A_MIE:       rval = mie_q;
            A_MTVEC:     rval = mtvec_q;
            A_MSCRATCH:  rval = mscratch_q;
            A_MEPC:      rval = mepc_q;
            A_MCAUSE:    rval = mcause_q;
            A_MIP:       rval = mip_q;
            A_MCYCLE:    rval = mcycle_q[31:0];
            A_MCYCLEH:   rval = mcycle_q[63:32];
            A_MINSTRET:  rval = minstret_q[31:0];
            A_MINSTRETH: rval = minstret_q[63:32];
            default:     rval = 32'd0;
        endcase
    end

    logic [31:0] newval;
    always_comb begin
        unique case (funct3[1:0])
            2'b01:   newval = wval;          // CSRRW
            2'b10:   newval = rval | wval;   // CSRRS
            2'b11:   newval = rval & ~wval;  // CSRRC
            default: newval = rval;
        endcase
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            mstatus_q <= 32'd0; mie_q <= 32'd0; mtvec_q <= 32'd0;
            mscratch_q <= 32'd0; mepc_q <= 32'd0; mcause_q <= 32'd0; mip_q <= 32'd0;
            mcycle_q <= 64'd0; minstret_q <= 64'd0;
        end else begin
            mcycle_q <= mcycle_q + 64'd1;
            if (instret_pulse) minstret_q <= minstret_q + 64'd1;
            if (en) begin
                unique case (addr)
                    A_MSTATUS:  mstatus_q  <= newval;
                    A_MIE:      mie_q      <= newval;
                    A_MTVEC:    mtvec_q    <= newval;
                    A_MSCRATCH: mscratch_q <= newval;
                    A_MEPC:     mepc_q     <= newval;
                    A_MCAUSE:   mcause_q   <= newval;
                    default: ;
                endcase
            end
        end
    end
endmodule : csr_file
