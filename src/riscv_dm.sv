// riscv_dm.sv — RISC-V Debug Module (0.13.2 subset).
// v1 scope: dmcontrol (dmactive/haltreq/resumereq), dmstatus, and the System
// Bus Access block (sbcs, sbaddress0, sbdata0 with read/write + autoincrement)
// — enough for OpenOCD to halt the hart and load/verify programs in SRAM.
// Abstract register-access commands land with the core halt FSM in Phase 4b.
`default_nettype none

module riscv_dm #(
    parameter int unsigned ABITS = 7
)(
    input  wire logic            clk,
    input  wire logic            rst,

    // DMI from riscv_dtm
    input  wire logic            req_valid,
    input  wire logic [ABITS-1:0] req_addr,
    input  wire logic [31:0]     req_wdata,
    input  wire logic [1:0]      req_op,
    output logic                 rsp_valid,
    output logic [31:0]          rsp_rdata,
    output logic [1:0]           rsp_status,

    // hart control
    output logic                 halt_req,
    input  wire logic            halted,

    // system bus master (to SoC fabric / SRAM)
    output logic                 sb_re,
    output logic                 sb_we,
    output logic [31:0]          sb_addr,
    output logic [31:0]          sb_wdata,
    input  wire logic [31:0]     sb_rdata
);
    localparam logic [6:0] A_DMCONTROL = 7'h10;
    localparam logic [6:0] A_DMSTATUS  = 7'h11;
    localparam logic [6:0] A_HARTINFO  = 7'h12;
    localparam logic [6:0] A_SBCS      = 7'h38;
    localparam logic [6:0] A_SBADDR0   = 7'h39;
    localparam logic [6:0] A_SBDATA0   = 7'h3C;

    logic dmactive_q, haltreq_q;
    logic sbautoinc_q, sbreadonaddr_q, sbreadondata_q;
    logic [31:0] sbaddr_q, sbdata_q;
    logic sb_pending_rd_q, sb_pending2_q;

    assign halt_req = dmactive_q & haltreq_q;  // ignored unless DM enabled

    // dmstatus: version=2 (0.13), authenticated, halted/running mirrors hart
    wire logic [31:0] dmstatus_val = {
        14'd0,
        1'b0, 1'b0,                 // impebreak etc
        2'd0,
        halted, halted,             // allhalted, anyhalted  [9:8]
        ~halted, ~halted,           // allrunning, anyrunning [11:10] -> note order below
        4'b0000,
        1'b1,                       // authenticated
        3'd2                        // version = 0.13
    };
    // (bit-exact field packing refined when OpenOCD co-sim lands in Phase 4b)

    wire logic [31:0] sbcs_val = {
        3'd1, 6'd0, 1'b0, 1'b0, 1'b0,
        3'd2,                       // sbaccess = 32-bit
        sbautoinc_q, sbreadondata_q,
        3'd0, 7'd32, 5'b00111       // sbasize=32, supports 8/16/32
    };

    always_ff @(posedge clk) begin
        rsp_valid <= 1'b0;
        sb_re     <= 1'b0;
        sb_we     <= 1'b0;

        if (rst) begin
            dmactive_q <= 1'b0; haltreq_q <= 1'b0;
            sbautoinc_q <= 1'b0; sbreadonaddr_q <= 1'b0; sbreadondata_q <= 1'b0;
            sbaddr_q <= 32'd0; sbdata_q <= 32'd0;
            sb_pending_rd_q <= 1'b0; sb_pending2_q <= 1'b0;
            rsp_status <= 2'd0;
        end else begin
            // complete a system-bus read two cycles after issuing it
            // (cycle 1: sb_re seen by sync SRAM; cycle 2: rdata valid)
            sb_pending2_q <= sb_pending_rd_q;
            sb_pending_rd_q <= 1'b0;
            if (sb_pending2_q) sbdata_q <= sb_rdata;

            if (req_valid) begin
                rsp_valid  <= 1'b1;
                rsp_status <= 2'd0;
                unique case (req_addr)
                    A_DMCONTROL: begin
                        if (req_op == 2'b10) begin
                            dmactive_q <= req_wdata[0];
                            haltreq_q  <= req_wdata[31];
                            if (req_wdata[30]) haltreq_q <= 1'b0; // resumereq clears
                        end
                        rsp_rdata <= {haltreq_q, 30'd0, dmactive_q};
                    end
                    A_DMSTATUS: rsp_rdata <= dmstatus_val;
                    A_HARTINFO: rsp_rdata <= 32'd0;
                    A_SBCS: begin
                        if (req_op == 2'b10) begin
                            sbautoinc_q    <= req_wdata[16];
                            sbreadondata_q <= req_wdata[15];
                            sbreadonaddr_q <= req_wdata[20];
                        end
                        rsp_rdata <= sbcs_val;
                    end
                    A_SBADDR0: begin
                        if (req_op == 2'b10) begin
                            sbaddr_q <= req_wdata;
                            if (sbreadonaddr_q) begin
                                sb_re <= 1'b1;
                                sb_addr <= req_wdata;
                                sb_pending_rd_q <= 1'b1;
                            end
                        end
                        rsp_rdata <= sbaddr_q;
                    end
                    A_SBDATA0: begin
                        if (req_op == 2'b10) begin
                            sb_we    <= 1'b1;
                            sb_addr  <= sbaddr_q;
                            sb_wdata <= req_wdata;
                            sbdata_q <= req_wdata;
                            if (sbautoinc_q) sbaddr_q <= sbaddr_q + 32'd4;
                        end else if (req_op == 2'b01) begin
                            rsp_rdata <= sbdata_q;
                            if (sbreadondata_q) begin
                                sb_re <= 1'b1;
                                sb_addr <= sbaddr_q;
                                sb_pending_rd_q <= 1'b1;
                                if (sbautoinc_q) sbaddr_q <= sbaddr_q + 32'd4;
                            end
                        end
                        if (req_op != 2'b01) rsp_rdata <= sbdata_q;
                    end
                    default: rsp_rdata <= 32'd0;
                endcase
            end
        end
    end
endmodule : riscv_dm
