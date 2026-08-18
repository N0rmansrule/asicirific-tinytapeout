// serial_core.sv — bit-serial RV32E core (the one-tile-class ASICirific).
// Instructions are fetched as whole words and decoded in parallel, but the
// datapath runs one bit per clock: operands stream LSB first from the shift-
// register file through the one-bit ALU, and results stream back in. That trades
// speed for area, which is the whole point of fitting a tile. This is the full
// RV32I integer set: ALU and immediate ops, LUI, AUIPC, every branch, JAL, JALR,
// loads and stores (byte, half, word), and shifts. The memory port uses a ready
// handshake, so the same core drives fast on-chip peripherals and slow external
// QSPI flash and PSRAM. Most instructions take a couple of 32-cycle passes.
`default_nettype none

module serial_core
    import asicirific_pkg::*;
#(
    parameter logic [31:0] RESET_PC = 32'h0000_0000
)(
    input  wire logic        clk,
    input  wire logic        rst,
    output logic [31:0]      mem_addr,
    output logic [31:0]      mem_wdata,
    output logic [3:0]       mem_be,
    output logic             mem_we,
    output logic             mem_re,
    input  wire logic [31:0] mem_rdata,
    input  wire logic        mem_ready
);
    // ---- state ----
    typedef enum logic [3:0] {
        S_FETCH, S_ALU, S_CMP, S_TGT, S_LINK, S_JADDR,
        S_ADDR, S_LOAD, S_LDWB, S_STORE, S_SHCP, S_SHIFT, S_NEXT
    } st_t;
    st_t st;

    logic [31:0] pc, ir, imm_sr, tgt_sr, addr_sr, data_sr;
    logic [5:0]  bitcnt;
    logic [4:0]  shamt;
    logic        zero_acc, cmp_taken;

    // ---- decode ----
    wire [6:0] opc = ir[6:0];
    wire [4:0] rd  = ir[11:7];
    wire [2:0] f3  = ir[14:12];
    wire [4:0] rs1 = ir[19:15];
    wire [4:0] rs2 = ir[24:20];
    wire [6:0] f7  = ir[31:25];

    wire is_lui   = (opc == OPC_LUI);
    wire is_auipc = (opc == OPC_AUIPC);
    wire is_opimm = (opc == OPC_OPIMM);
    wire is_op    = (opc == OPC_OP);
    wire is_br    = (opc == OPC_BRANCH);
    wire is_jal   = (opc == OPC_JAL);
    wire is_jalr  = (opc == OPC_JALR);
    wire is_load  = (opc == OPC_LOAD);
    wire is_store = (opc == OPC_STORE);
    wire is_shift = (is_op || is_opimm) && ((f3 == 3'b001) || (f3 == 3'b101));
    wire shift_right = (f3 == 3'b101);
    wire shift_arith = f7[5];
    wire alu_writes = (is_lui || is_auipc || is_opimm || is_op) && !is_shift;

    imm_sel_t f_sel;
    always_comb begin
        unique case (mem_rdata[6:0])
            OPC_STORE:          f_sel = IMM_S;
            OPC_BRANCH:         f_sel = IMM_B;
            OPC_LUI, OPC_AUIPC: f_sel = IMM_U;
            OPC_JAL:            f_sel = IMM_J;
            default:            f_sel = IMM_I;
        endcase
    end
    logic [31:0] imm_full;
    imm_gen u_imm (.inst(mem_rdata), .sel(f_sel), .imm(imm_full));

    // ---- ALU op select ----
    alu_op_t alu_op;
    always_comb begin
        alu_op = ALU_ADD;
        if (is_op || is_opimm) begin
            unique case (f3)
                3'b000:  alu_op = alu_op_t'((is_op && f7[5]) ? ALU_SUB : ALU_ADD);
                3'b111:  alu_op = ALU_AND;
                3'b110:  alu_op = ALU_OR;
                3'b100:  alu_op = ALU_XOR;
                3'b010:  alu_op = ALU_SLT;
                3'b011:  alu_op = ALU_SLTU;
                default: alu_op = ALU_ADD;
            endcase
        end
    end

    // ---- register file ----
    logic rs1_bit, rs2_bit, rf_we, rf_wbit, rf_en, rf_shl, rf_shr, rf_shin, rd_msb;
    serial_rf u_rf (
        .clk(clk), .rst(rst), .en(rf_en),
        .rs1(rs1[3:0]), .rs2(rs2[3:0]), .rd(rd[3:0]),
        .we(rf_we), .wbit(rf_wbit),
        .shl(rf_shl), .shr(rf_shr), .shin(rf_shin),
        .rs1_bit(rs1_bit), .rs2_bit(rs2_bit), .rd_msb(rd_msb)
    );

    // ---- serial ALU ----
    wire use_pc_a  = (st == S_TGT) || is_auipc;
    wire use_imm_b = (st == S_ALU && (is_opimm || is_lui || is_auipc)) ||
                     (st == S_TGT) || (st == S_JADDR) || (st == S_ADDR);
    wire a_bit = use_pc_a ? pc[bitcnt] : (is_lui ? 1'b0 : rs1_bit);
    wire b_bit = use_imm_b ? imm_sr[0] : rs2_bit;
    alu_op_t alu_op_eff;
    always_comb begin
        if (st == S_CMP)                                             alu_op_eff = ALU_SUB;
        else if (st == S_TGT || st == S_JADDR || st == S_ADDR ||
                 st == S_SHCP)                                       alu_op_eff = ALU_ADD;
        else                                                         alu_op_eff = alu_op;
    end
    logic alu_y, alu_cout, alu_en, alu_init;
    serial_alu u_alu (
        .clk(clk), .rst(rst), .init(alu_init), .en(alu_en),
        .op(alu_op_eff), .a(a_bit), .b(b_bit), .y(alu_y), .last_cout(alu_cout)
    );

    wire [31:0] pc4 = pc + 32'd4;

    // branch comparison flags, resolved at the final (MSB) bit of the subtract
    wire cmp_lt_u = ~alu_cout;
    wire cmp_lt_s = (rs1_bit ^ rs2_bit) ? rs1_bit : alu_y;
    wire cmp_zero = zero_acc && (alu_y == 1'b0);
    logic br_taken;
    branch_comp u_bc (
        .funct3(f3), .zero(cmp_zero),
        .lt_signed(cmp_lt_s), .lt_unsigned(cmp_lt_u), .taken(br_taken)
    );

    // ---- load / store data formatting ----
    logic [31:0] ld_result;
    load_unit u_ld (.rdata(mem_rdata), .addr_lo(addr_sr[1:0]), .funct3(f3), .out(ld_result));
    logic [31:0] st_wdata; logic [3:0] st_be;
    store_unit u_st (.wdata_in(data_sr), .addr_lo(addr_sr[1:0]), .funct3(f3),
                     .wdata_out(st_wdata), .be(st_be));

    // ---- memory request ----
    always_comb begin
        mem_re    = (st == S_FETCH) || (st == S_LOAD);
        mem_we    = (st == S_STORE);
        mem_addr  = (st == S_FETCH) ? pc : {addr_sr[31:2], 2'b00};
        mem_wdata = st_wdata;
        mem_be    = st_be;
    end

    // ---- datapath control ----
    wire alu_pass = (st == S_ALU) || (st == S_CMP) || (st == S_TGT) ||
                    (st == S_LINK) || (st == S_JADDR) || (st == S_ADDR) ||
                    (st == S_LDWB) || (st == S_SHCP);
    always_comb begin
        alu_en   = alu_pass;
        alu_init = alu_pass && (bitcnt == 6'd0);
        rf_en    = alu_pass;
        rf_we    = (st == S_ALU && alu_writes) ||
                   (st == S_LINK && (is_jal || is_jalr)) ||
                   (st == S_LDWB) ||
                   (st == S_SHCP);
        // writeback bit source per pass
        if (st == S_LINK)      rf_wbit = pc4[bitcnt];
        else if (st == S_LDWB) rf_wbit = data_sr[0];
        else if (st == S_SHCP) rf_wbit = rs1_bit;         // copy rs1 into rd
        else                   rf_wbit = alu_y;
        // shift controls (only in S_SHIFT)
        rf_shl  = (st == S_SHIFT) && !shift_right;
        rf_shr  = (st == S_SHIFT) &&  shift_right;
        rf_shin = shift_arith ? rd_msb : 1'b0;            // SRA fills with sign
    end

    // ---- FSM ----
    always_ff @(posedge clk) begin
        if (rst) begin
            st <= S_FETCH;
            pc <= RESET_PC;
        end else begin
            unique case (st)
                S_FETCH: if (mem_ready) begin
                    ir       <= mem_rdata;
                    imm_sr   <= imm_full;
                    bitcnt   <= 6'd0;
                    zero_acc <= 1'b1;
                    shamt    <= mem_rdata[24:20];          // for immediate shifts
                    unique case (mem_rdata[6:0])
                        OPC_BRANCH: st <= S_CMP;
                        OPC_JAL:    st <= S_LINK;
                        OPC_JALR:   st <= S_LINK;
                        OPC_LOAD:   st <= S_ADDR;
                        OPC_STORE:  st <= S_ADDR;
                        default: begin
                            if (((mem_rdata[6:0]==OPC_OP)||(mem_rdata[6:0]==OPC_OPIMM))
                                && ((mem_rdata[14:12]==3'b001)||(mem_rdata[14:12]==3'b101)))
                                 st <= S_SHCP;             // shift: copy then shift
                            else st <= S_ALU;
                        end
                    endcase
                end

                S_ALU: begin
                    if (use_imm_b) imm_sr <= {1'b0, imm_sr[31:1]};
                    bitcnt <= bitcnt + 6'd1;
                    if (bitcnt == 6'd31) st <= S_NEXT;
                end

                S_CMP: begin
                    if (alu_y != 1'b0) zero_acc <= 1'b0;
                    if (bitcnt == 6'd31) begin
                        cmp_taken <= br_taken;      // from branch_comp
                        bitcnt    <= 6'd0;
                        st        <= S_TGT;
                    end else bitcnt <= bitcnt + 6'd1;
                end

                S_TGT: begin
                    tgt_sr <= {alu_y, tgt_sr[31:1]};
                    imm_sr <= {1'b0, imm_sr[31:1]};
                    if (bitcnt == 6'd31) begin
                        if (is_jal || cmp_taken) pc <= {alu_y, tgt_sr[31:1]};
                        else                     pc <= pc4;
                        st <= S_FETCH;
                    end else bitcnt <= bitcnt + 6'd1;
                end

                S_LINK: begin
                    bitcnt <= bitcnt + 6'd1;
                    if (bitcnt == 6'd31) begin
                        bitcnt <= 6'd0;
                        st     <= is_jalr ? S_JADDR : S_TGT;
                    end
                end

                S_JADDR: begin
                    tgt_sr <= {alu_y, tgt_sr[31:1]};
                    imm_sr <= {1'b0, imm_sr[31:1]};
                    if (bitcnt == 6'd31) begin
                        pc <= {alu_y, tgt_sr[31:1]} & ~32'd1;
                        st <= S_FETCH;
                    end else bitcnt <= bitcnt + 6'd1;
                end

                // load/store: compute rs1+imm into addr_sr; capture rs2 into data_sr
                S_ADDR: begin
                    addr_sr <= {alu_y, addr_sr[31:1]};
                    data_sr <= {rs2_bit, data_sr[31:1]};
                    imm_sr  <= {1'b0, imm_sr[31:1]};
                    if (bitcnt == 6'd31) begin
                        st <= is_load ? S_LOAD : S_STORE;
                    end else bitcnt <= bitcnt + 6'd1;
                end

                S_LOAD: if (mem_ready) begin
                    data_sr <= ld_result;                  // formatted load word
                    bitcnt  <= 6'd0;
                    st      <= S_LDWB;
                end

                S_LDWB: begin
                    data_sr <= {1'b0, data_sr[31:1]};      // stream into rd LSB first
                    bitcnt  <= bitcnt + 6'd1;
                    if (bitcnt == 6'd31) st <= S_NEXT;
                end

                S_STORE: if (mem_ready) st <= S_NEXT;

                // shift: copy rs1 into rd over a pass, capture register shamt
                S_SHCP: begin
                    if (bitcnt < 6'd5 && is_op) shamt[bitcnt[2:0]] <= rs2_bit;
                    bitcnt <= bitcnt + 6'd1;
                    if (bitcnt == 6'd31) begin
                        st <= (shamt == 5'd0) ? S_NEXT : S_SHIFT;
                    end
                end

                S_SHIFT: begin
                    shamt <= shamt - 5'd1;                  // one position per cycle
                    if (shamt == 5'd1) st <= S_NEXT;
                end

                S_NEXT: begin
                    pc <= pc4;
                    st <= S_FETCH;
                end

                default: st <= S_FETCH;
            endcase
        end
    end
endmodule : serial_core
