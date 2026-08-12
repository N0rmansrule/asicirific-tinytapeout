// core_top.sv — ASICirific six-stage RV32IM pipeline.
//
//   F1 -> F2 -> D -> X -> M -> W
//   F1: PC generation, imem address presented (sync SRAM)
//   F2: instruction arrives; branch prediction (queried on F1 PC)
//   D : decode, register read (with W write-through bypass), immediates
//   X : ALU / branch resolve / mul / div / CSR; forwarding from M and W
//   M : data memory access (sync SRAM)
//   W : load align, writeback
//
// Branches resolve in X. Mispredict flushes F2 and D (predict-not-taken
// fallback when ENABLE_BP=0). Load-use = 1 stall + forward from W.
`default_nettype none

module core_top
    import asicirific_pkg::*;
#(
    parameter logic [31:0] RESET_PC  = 32'h0000_0000,
    parameter bit          ENABLE_BP = 1'b1,
    parameter bit          ENABLE_M  = 1'b1
)(
    input  wire logic        clk,
    input  wire logic        rst,

    // instruction memory (synchronous, 1-cycle)
    output logic [31:0]      imem_addr,
    input  wire logic [31:0] imem_rdata,

    // data memory (synchronous, 1-cycle)
    output logic [31:0]      dmem_addr,
    output logic [31:0]      dmem_wdata,
    output logic [3:0]       dmem_be,
    output logic             dmem_we,
    output logic             dmem_re,
    input  wire logic [31:0] dmem_rdata,

    // debug hooks (riscv_dm, Phase 4 wiring)
    input  wire logic        dbg_halt_req,
    output logic             dbg_halted
);

    // ------------------------------------------------------------------ F1
    logic        stall, bubble_x, flush;
    logic [31:0] pc_f1, pc_next, redirect_pc;
    logic        redirect;                  // from X resolve
    logic        pred_taken_f1;
    logic [31:0] pred_target_f1;

    // synchronize the debug halt request into the core clock domain; resets to
    // 0 so an un-clocked/idle DM can never freeze the core with an X.
    logic halt_ff1, halt_ff2;
    always_ff @(posedge clk) begin
        if (rst) begin halt_ff1 <= 1'b0; halt_ff2 <= 1'b0; end
        else     begin halt_ff1 <= (dbg_halt_req === 1'b1); halt_ff2 <= halt_ff1; end
    end
    wire logic halt = halt_ff2;
    assign pc_next = rst                         ? RESET_PC        :
                     halt                        ? pc_f1           :
                     redirect                    ? redirect_pc     :
                     stall                       ? pc_f1           :
                     (ENABLE_BP && pred_taken_f1)? pred_target_f1  :
                                                   pc_f1 + 32'd4;

    always_ff @(posedge clk) begin
        if (rst) pc_f1 <= RESET_PC;
        else     pc_f1 <= pc_next;
    end

    assign imem_addr = pc_next;   // sync mem: present next addr, data in F2 of that PC

    // ------------------------------------------------------------------ F2
    logic [31:0] pc_f2;
    logic        valid_f2, pred_taken_f2;

    logic [31:0] inst_f2;

    always_ff @(posedge clk) begin
        if (rst || redirect) begin
            valid_f2 <= 1'b0;
            pred_taken_f2 <= 1'b0;
        end else if (!stall && !halt) begin
            pc_f2    <= pc_f1;
            inst_f2  <= imem_rdata;   // rdata this cycle = mem[pc_f1]
            valid_f2 <= 1'b1;
            pred_taken_f2 <= ENABLE_BP && pred_taken_f1;
        end
    end

    // ------------------------------------------------------------------ D
    logic [31:0] pc_d, inst_d;
    logic        valid_d, pred_taken_d;

    always_ff @(posedge clk) begin
        if (rst || redirect) valid_d <= 1'b0;
        else if (!stall) begin
            pc_d         <= pc_f2;
            inst_d       <= inst_f2;
            valid_d      <= valid_f2;
            pred_taken_d <= pred_taken_f2;
        end
    end

    ctrl_t ctrl_d;
    control_unit #(.ENABLE_M(ENABLE_M)) u_ctrl (.inst(inst_d), .ctrl(ctrl_d));

    wire logic [4:0] rs1_d = inst_d[19:15];
    wire logic [4:0] rs2_d = inst_d[24:20];
    wire logic [4:0] rd_d  = inst_d[11:7];

    logic [31:0] imm_d;
    imm_gen u_imm (.inst(inst_d), .sel(ctrl_d.imm_sel), .imm(imm_d));

    // regfile (W writes, D reads with write-through)
    logic        rf_we_w;
    logic [4:0]  rd_w;
    logic [31:0] wb_data_w;
    logic [31:0] rf_rdata1, rf_rdata2;

    reg_file u_rf (
        .clk(clk), .we(rf_we_w), .waddr(rd_w), .wdata(wb_data_w),
        .raddr1(rs1_d), .raddr2(rs2_d), .rdata1(rf_rdata1), .rdata2(rf_rdata2)
    );

    wire logic uses_rs1_d = ctrl_d.legal && !(ctrl_d.is_jal) &&
                            (inst_d[6:0] != OPC_LUI) && (inst_d[6:0] != OPC_AUIPC);
    wire logic uses_rs2_d = ctrl_d.is_branch || ctrl_d.mem_write ||
                            (inst_d[6:0] == OPC_OP);

    // ------------------------------------------------------------------ X
    ctrl_t       ctrl_x;
    logic [31:0] pc_x, imm_x, rs1v_x, rs2v_x;
    logic [4:0]  rs1_x, rs2_x, rd_x;
    logic [11:0] csr_addr_x;
    logic        valid_x, pred_taken_x;

    always_ff @(posedge clk) begin
        if (rst || redirect || bubble_x || (stall && !bubble_x)) begin
            // stall without bubble means div hold: keep X contents
            if (rst || redirect || bubble_x) begin
                valid_x <= 1'b0;
                ctrl_x  <= '0;
            end
        end else begin
            ctrl_x       <= valid_d ? ctrl_d : '0;
            valid_x      <= valid_d;
            pc_x         <= pc_d;
            imm_x        <= imm_d;
            rs1v_x       <= rf_rdata1;
            rs2v_x       <= rf_rdata2;
            rs1_x        <= rs1_d;
            rs2_x        <= rs2_d;
            rd_x         <= valid_d && ctrl_d.rf_we ? rd_d : 5'd0;
            csr_addr_x   <= inst_d[31:20];
            pred_taken_x <= pred_taken_d;
        end
    end

    // forwarding
    logic [1:0]  fwd_a, fwd_b;
    logic [4:0]  rd_m;
    logic        rf_we_m, is_load_m;
    logic [31:0] alu_m;

    forwarding_unit u_fwd (
        .rs1_x(rs1_x), .rs2_x(rs2_x),
        .rd_m(rd_m), .rf_we_m(rf_we_m), .is_load_m(is_load_m),
        .rd_w(rd_w), .rf_we_w(rf_we_w),
        .fwd_a(fwd_a), .fwd_b(fwd_b)
    );

    logic [31:0] op_a_fwd, op_b_fwd;
    assign op_a_fwd = (fwd_a == 2'b01) ? alu_m :
                      (fwd_a == 2'b10) ? wb_data_w : rs1v_x;
    assign op_b_fwd = (fwd_b == 2'b01) ? alu_m :
                      (fwd_b == 2'b10) ? wb_data_w : rs2v_x;

    logic [31:0] alu_a, alu_b, alu_y;
    assign alu_a = ctrl_x.alu_a_pc  ? pc_x  : op_a_fwd;
    assign alu_b = ctrl_x.alu_b_imm ? imm_x : op_b_fwd;

    alu u_alu (.a(alu_a), .b(alu_b), .op(ctrl_x.alu_op), .y(alu_y));

    // branch resolve
    br_cmp_t cmp;
    branch_comp u_bc (.rs1(op_a_fwd), .rs2(op_b_fwd), .cmp(cmp));

    logic br_taken;
    always_comb begin
        unique case (ctrl_x.funct3)
            3'b000: br_taken = cmp.eq;    // BEQ
            3'b001: br_taken = ~cmp.eq;   // BNE
            3'b100: br_taken = cmp.lt;    // BLT
            3'b101: br_taken = ~cmp.lt;   // BGE
            3'b110: br_taken = cmp.ltu;   // BLTU
            3'b111: br_taken = ~cmp.ltu;  // BGEU
            default: br_taken = 1'b0;
        endcase
    end

    logic        taken_x;
    logic [31:0] target_x;
    assign taken_x  = valid_x && ((ctrl_x.is_branch && br_taken) ||
                                   ctrl_x.is_jal || ctrl_x.is_jalr);
    assign target_x = ctrl_x.is_jalr ? ((op_a_fwd + imm_x) & ~32'd1)
                                     : (pc_x + imm_x);

    // redirect when actual outcome disagrees with the prediction carried along
    assign redirect    = valid_x && (taken_x != pred_taken_x) &&
                         (ctrl_x.is_branch || ctrl_x.is_jal || ctrl_x.is_jalr);
    assign redirect_pc = taken_x ? target_x : (pc_x + 32'd4);

    // mul / div
    logic [31:0] mul_y;
    mul_unit u_mul (.a(op_a_fwd), .b(op_b_fwd), .funct3(ctrl_x.funct3), .y(mul_y));

    logic div_busy, div_done, div_started_q;
    logic [31:0] div_y;
    wire logic div_req = valid_x && ctrl_x.is_div;
    wire logic div_start = div_req && !div_started_q && !div_busy && !div_done;

    always_ff @(posedge clk) begin
        if (rst)              div_started_q <= 1'b0;
        else if (div_start)   div_started_q <= 1'b1;
        else if (!stall)      div_started_q <= 1'b0;   // X advances
    end

    div_unit u_div (
        .clk(clk), .rst(rst), .start(div_start),
        .a(op_a_fwd), .b(op_b_fwd), .funct3(ctrl_x.funct3),
        .busy(div_busy), .done(div_done), .y(div_y)
    );

    // csr
    logic [31:0] csr_rval;
    wire logic csr_en = valid_x && ctrl_x.is_csr && !stall;
    wire logic [31:0] csr_wval = ctrl_x.csr_use_imm ? {27'd0, rs1_x} : op_a_fwd;

    csr_file u_csr (
        .clk(clk), .rst(rst),
        .en(csr_en), .addr(csr_addr_x), .funct3(ctrl_x.funct3),
        .wval(csr_wval), .rval(csr_rval),
        .instret_pulse(valid_x && !stall)
    );

    // X result mux (what M/W will see as "alu")
    logic [31:0] xres;
    assign xres = ctrl_x.is_mul ? mul_y :
                  ctrl_x.is_div ? div_y :
                  ctrl_x.is_csr ? csr_rval : alu_y;

    // store data prep
    logic [31:0] st_wdata;
    logic [3:0]  st_be;
    store_unit u_st (
        .wdata_in(op_b_fwd), .addr_lo(alu_y[1:0]), .funct3(ctrl_x.funct3),
        .wdata_out(st_wdata), .be(st_be)
    );

    // hazards
    hazard_unit u_hz (
        .rs1_d(rs1_d), .rs2_d(rs2_d),
        .uses_rs1_d(valid_d && uses_rs1_d), .uses_rs2_d(valid_d && uses_rs2_d),
        .rd_x(rd_x), .mem_read_x(valid_x && ctrl_x.mem_read),
        .div_busy(div_req && !div_done),
        .stall(stall), .bubble_x(bubble_x)
    );

    // ------------------------------------------------------------------ M
    ctrl_t       ctrl_m;
    logic [31:0] pc_m, xres_m, st_wdata_m;
    logic [3:0]  st_be_m;
    logic        valid_m;

    always_ff @(posedge clk) begin
        if (rst) begin
            valid_m <= 1'b0; ctrl_m <= '0;
        end else begin
            // X->M advances unless div holding (stall && !bubble_x keeps X, sends bubble)
            if (stall && !bubble_x) begin
                valid_m <= 1'b0; ctrl_m <= '0;
            end else begin
                ctrl_m     <= valid_x ? ctrl_x : '0;
                valid_m    <= valid_x;
                pc_m       <= pc_x;
                xres_m     <= xres;
                st_wdata_m <= st_wdata;
                st_be_m    <= st_be;
                rd_m_q     <= rd_x;
            end
        end
    end

    logic [4:0] rd_m_q;
    assign rd_m      = valid_m ? rd_m_q : 5'd0;
    assign rf_we_m   = valid_m && ctrl_m.rf_we;
    assign is_load_m = valid_m && ctrl_m.mem_read;
    assign alu_m     = xres_m;

    assign dmem_addr  = {xres_m[31:2], 2'b00};
    assign dmem_wdata = st_wdata_m;
    assign dmem_be    = st_be_m;
    assign dmem_we    = valid_m && ctrl_m.mem_write;
    assign dmem_re    = valid_m && ctrl_m.mem_read;

    // ------------------------------------------------------------------ W
    ctrl_t       ctrl_w;
    logic [31:0] pc_w, xres_w;
    logic [1:0]  addr_lo_w;
    logic        valid_w;
    logic [4:0]  rd_w_q;

    always_ff @(posedge clk) begin
        if (rst) begin
            valid_w <= 1'b0; ctrl_w <= '0;
        end else begin
            ctrl_w    <= valid_m ? ctrl_m : '0;
            valid_w   <= valid_m;
            pc_w      <= pc_m;
            xres_w    <= xres_m;
            addr_lo_w <= xres_m[1:0];
            rd_w_q    <= rd_m_q;
        end
    end

    logic [31:0] ld_data_w;
    load_unit u_ld (
        .rdata(dmem_rdata), .addr_lo(addr_lo_w), .funct3(ctrl_w.funct3),
        .out(ld_data_w)
    );

    always_comb begin
        unique case (ctrl_w.wb_sel)
            WB_ALU: wb_data_w = xres_w;
            WB_MEM: wb_data_w = ld_data_w;
            WB_PC4: wb_data_w = pc_w + 32'd4;
            WB_CSR: wb_data_w = xres_w;
            default: wb_data_w = xres_w;
        endcase
    end

    assign rd_w    = valid_w && ctrl_w.rf_we ? rd_w_q : 5'd0;
    assign rf_we_w = valid_w && ctrl_w.rf_we;

    // ------------------------------------------------------------------ BP
    bp_top u_bp (
        .clk(clk), .rst(rst),
        .pc_if(pc_f1), .pred_taken(pred_taken_f1), .pred_target(pred_target_f1),
        .upd_valid(valid_x && (ctrl_x.is_branch || ctrl_x.is_jal || ctrl_x.is_jalr) && !stall),
        .upd_pc(pc_x), .upd_taken(taken_x), .upd_target(target_x),
        .ras_push(1'b0), .ras_push_addr(32'd0), .ras_pop(1'b0)
    );

    // ------------------------------------------------------------------ debug
    assign dbg_halted = dbg_halt_req;  // v1: acknowledge halt request (full FSM = Phase 4b)

endmodule : core_top
