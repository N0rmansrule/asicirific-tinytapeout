`default_nettype none
module alu (
	a,
	b,
	op,
	y
);
	reg _sv2v_0;
	input wire [31:0] a;
	input wire [31:0] b;
	input wire [3:0] op;
	output reg [31:0] y;
	reg sub_mode;
	reg [32:0] addsub;
	reg [4:0] shamt;
	reg slt_bit;
	reg sltu_bit;
	always @(*) begin
		if (_sv2v_0)
			;
		shamt = b[4:0];
		sub_mode = ((op == 4'd1) || (op == 4'd5)) || (op == 4'd6);
		addsub = ({1'b0, a} + {1'b0, (sub_mode ? ~b : b)}) + {32'd0, sub_mode};
		slt_bit = (a[31] != b[31] ? a[31] : addsub[31]);
		sltu_bit = ~addsub[32];
		(* full_case, parallel_case *)
		case (op)
			4'd0: y = addsub[31:0];
			4'd1: y = addsub[31:0];
			4'd2: y = a & b;
			4'd3: y = a | b;
			4'd4: y = a ^ b;
			4'd5: y = {31'd0, slt_bit};
			4'd6: y = {31'd0, sltu_bit};
			4'd7: y = a << shamt;
			4'd8: y = a >> shamt;
			4'd9: y = $signed(a) >>> shamt;
			4'd10: y = b;
			4'd11: y = a & ~b;
			default: y = 32'd0;
		endcase
	end
	initial _sv2v_0 = 0;
endmodule
`default_nettype none
`default_nettype none
module bp_top (
	clk,
	rst,
	pc_if,
	pred_taken,
	pred_target,
	upd_valid,
	upd_pc,
	upd_taken,
	upd_target,
	ras_push,
	ras_push_addr,
	ras_pop
);
	parameter [31:0] HIST_BITS = 8;
	parameter [31:0] IDX_BITS = 10;
	parameter [31:0] BTB_IDX = 6;
	input wire clk;
	input wire rst;
	input wire [31:0] pc_if;
	output wire pred_taken;
	output wire [31:0] pred_target;
	input wire upd_valid;
	input wire [31:0] upd_pc;
	input wire upd_taken;
	input wire [31:0] upd_target;
	input wire ras_push;
	input wire [31:0] ras_push_addr;
	input wire ras_pop;
	wire dir_taken;
	wire btb_hit;
	wire [31:0] btb_target;
	wire [31:0] ras_addr;
	wire ras_valid;
	gshare_predictor #(
		.HIST_BITS(HIST_BITS),
		.IDX_BITS(IDX_BITS)
	) u_gshare(
		.clk(clk),
		.rst(rst),
		.pc_if(pc_if),
		.pred_taken(dir_taken),
		.upd_valid(upd_valid),
		.upd_pc(upd_pc),
		.upd_taken(upd_taken)
	);
	btb #(.IDX_BITS(BTB_IDX)) u_btb(
		.clk(clk),
		.rst(rst),
		.pc_if(pc_if),
		.hit(btb_hit),
		.target(btb_target),
		.upd_valid(upd_valid && upd_taken),
		.upd_pc(upd_pc),
		.upd_target(upd_target)
	);
	ras u_ras(
		.clk(clk),
		.rst(rst),
		.push(ras_push),
		.push_addr(ras_push_addr),
		.pop(ras_pop),
		.top_addr(ras_addr),
		.top_valid(ras_valid)
	);
	assign pred_taken = dir_taken && btb_hit;
	assign pred_target = (ras_pop && ras_valid ? ras_addr : btb_target);
endmodule
`default_nettype none
module branch_comp (
	rs1,
	rs2,
	cmp
);
	reg _sv2v_0;
	input wire [31:0] rs1;
	input wire [31:0] rs2;
	output reg [2:0] cmp;
	always @(*) begin
		if (_sv2v_0)
			;
		cmp[2] = rs1 == rs2;
		cmp[1] = $signed(rs1) < $signed(rs2);
		cmp[0] = rs1 < rs2;
	end
	initial _sv2v_0 = 0;
endmodule
`default_nettype none
module btb (
	clk,
	rst,
	pc_if,
	hit,
	target,
	upd_valid,
	upd_pc,
	upd_target
);
	parameter [31:0] IDX_BITS = 6;
	parameter [31:0] TAG_BITS = 12;
	input wire clk;
	input wire rst;
	input wire [31:0] pc_if;
	output wire hit;
	output wire [31:0] target;
	input wire upd_valid;
	input wire [31:0] upd_pc;
	input wire [31:0] upd_target;
	localparam [31:0] ENTRIES = 1 << IDX_BITS;
	reg valid_q [ENTRIES - 1:0];
	reg [TAG_BITS - 1:0] tag_q [ENTRIES - 1:0];
	reg [31:0] tgt_q [ENTRIES - 1:0];
	wire [IDX_BITS - 1:0] li = pc_if[IDX_BITS + 1:2];
	wire [TAG_BITS - 1:0] lt = pc_if[IDX_BITS + 2+:TAG_BITS];
	wire [IDX_BITS - 1:0] ui = upd_pc[IDX_BITS + 1:2];
	wire [TAG_BITS - 1:0] ut = upd_pc[IDX_BITS + 2+:TAG_BITS];
	assign hit = valid_q[li] && (tag_q[li] == lt);
	assign target = tgt_q[li];
	always @(posedge clk)
		if (rst) begin : sv2v_autoblock_1
			reg signed [31:0] i;
			for (i = 0; i < ENTRIES; i = i + 1)
				valid_q[i] <= 1'b0;
		end
		else if (upd_valid) begin
			valid_q[ui] <= 1'b1;
			tag_q[ui] <= ut;
			tgt_q[ui] <= upd_target;
		end
endmodule
`default_nettype none
module bus_fabric (
	addr,
	sel
);
	reg _sv2v_0;
	input wire [31:0] addr;
	output reg [4:0] sel;
	always @(*) begin
		if (_sv2v_0)
			;
		sel = 5'b00000;
		if (addr[31:16] == 16'h2000)
			(* full_case, parallel_case *)
			case (addr[15:12])
				4'h0: sel = 5'b00001;
				4'h1: sel = 5'b00010;
				4'h2: sel = 5'b00100;
				4'h3: sel = 5'b01000;
				4'h4: sel = 5'b10000;
				default: sel = 5'b00000;
			endcase
	end
	initial _sv2v_0 = 0;
endmodule
`default_nettype none
module control_unit (
	inst,
	ctrl
);
	reg _sv2v_0;
	parameter [0:0] ENABLE_M = 1'b1;
	input wire [31:0] inst;
	output reg [24:0] ctrl;
	wire [6:0] opc = inst[6:0];
	wire [2:0] funct3 = inst[14:12];
	wire [6:0] funct7 = inst[31:25];
	wire is_m = funct7 == 7'b0000001;
	localparam [6:0] asicirific_pkg_OPC_AUIPC = 7'b0010111;
	localparam [6:0] asicirific_pkg_OPC_BRANCH = 7'b1100011;
	localparam [6:0] asicirific_pkg_OPC_FENCE = 7'b0001111;
	localparam [6:0] asicirific_pkg_OPC_JAL = 7'b1101111;
	localparam [6:0] asicirific_pkg_OPC_JALR = 7'b1100111;
	localparam [6:0] asicirific_pkg_OPC_LOAD = 7'b0000011;
	localparam [6:0] asicirific_pkg_OPC_LUI = 7'b0110111;
	localparam [6:0] asicirific_pkg_OPC_OP = 7'b0110011;
	localparam [6:0] asicirific_pkg_OPC_OPIMM = 7'b0010011;
	localparam [6:0] asicirific_pkg_OPC_STORE = 7'b0100011;
	localparam [6:0] asicirific_pkg_OPC_SYSTEM = 7'b1110011;
	always @(*) begin
		if (_sv2v_0)
			;
		ctrl = 1'sb0;
		ctrl[6-:3] = funct3;
		ctrl[14-:3] = 3'd0;
		ctrl[20-:4] = 4'd0;
		ctrl[22-:2] = 2'd0;
		(* full_case, parallel_case *)
		case (opc)
			asicirific_pkg_OPC_LUI: begin
				ctrl[24] = 1;
				ctrl[23] = 1;
				ctrl[20-:4] = 4'd10;
				ctrl[15] = 1;
				ctrl[14-:3] = 3'd3;
			end
			asicirific_pkg_OPC_AUIPC: begin
				ctrl[24] = 1;
				ctrl[23] = 1;
				ctrl[16] = 1;
				ctrl[15] = 1;
				ctrl[14-:3] = 3'd3;
			end
			asicirific_pkg_OPC_JAL: begin
				ctrl[24] = 1;
				ctrl[23] = 1;
				ctrl[10] = 1;
				ctrl[22-:2] = 2'd2;
				ctrl[14-:3] = 3'd4;
			end
			asicirific_pkg_OPC_JALR: begin
				ctrl[24] = 1;
				ctrl[23] = 1;
				ctrl[9] = 1;
				ctrl[22-:2] = 2'd2;
				ctrl[14-:3] = 3'd0;
			end
			asicirific_pkg_OPC_BRANCH: begin
				ctrl[24] = 1;
				ctrl[11] = 1;
				ctrl[14-:3] = 3'd2;
			end
			asicirific_pkg_OPC_LOAD: begin
				ctrl[24] = 1;
				ctrl[23] = 1;
				ctrl[8] = 1;
				ctrl[22-:2] = 2'd1;
				ctrl[15] = 1;
				ctrl[14-:3] = 3'd0;
			end
			asicirific_pkg_OPC_STORE: begin
				ctrl[24] = 1;
				ctrl[7] = 1;
				ctrl[15] = 1;
				ctrl[14-:3] = 3'd1;
			end
			asicirific_pkg_OPC_OPIMM: begin
				ctrl[24] = 1;
				ctrl[23] = 1;
				ctrl[15] = 1;
				ctrl[14-:3] = 3'd0;
				(* full_case, parallel_case *)
				case (funct3)
					3'b000: ctrl[20-:4] = 4'd0;
					3'b010: ctrl[20-:4] = 4'd5;
					3'b011: ctrl[20-:4] = 4'd6;
					3'b100: ctrl[20-:4] = 4'd4;
					3'b110: ctrl[20-:4] = 4'd3;
					3'b111: ctrl[20-:4] = 4'd2;
					3'b001: ctrl[20-:4] = 4'd7;
					3'b101: ctrl[20-:4] = (inst[30] ? 4'd9 : 4'd8);
					default: ctrl[24] = 0;
				endcase
			end
			asicirific_pkg_OPC_OP: begin
				ctrl[24] = 1;
				ctrl[23] = 1;
				if (is_m) begin
					ctrl[1] = ENABLE_M && (funct3[2] == 1'b0);
					ctrl[0] = ENABLE_M && (funct3[2] == 1'b1);
					ctrl[24] = ENABLE_M;
				end
				else
					(* full_case, parallel_case *)
					case (funct3)
						3'b000: ctrl[20-:4] = (inst[30] ? 4'd1 : 4'd0);
						3'b010: ctrl[20-:4] = 4'd5;
						3'b011: ctrl[20-:4] = 4'd6;
						3'b100: ctrl[20-:4] = 4'd4;
						3'b110: ctrl[20-:4] = 4'd3;
						3'b111: ctrl[20-:4] = 4'd2;
						3'b001: ctrl[20-:4] = 4'd7;
						3'b101: ctrl[20-:4] = (inst[30] ? 4'd9 : 4'd8);
						default: ctrl[24] = 0;
					endcase
			end
			asicirific_pkg_OPC_SYSTEM:
				if (funct3 != 3'b000) begin
					ctrl[24] = 1;
					ctrl[23] = 1;
					ctrl[3] = 1;
					ctrl[22-:2] = 2'd3;
					ctrl[2] = funct3[2];
				end
				else
					ctrl[24] = 1;
			asicirific_pkg_OPC_FENCE: ctrl[24] = 1;
			default: ctrl[24] = 0;
		endcase
	end
	initial _sv2v_0 = 0;
endmodule
`default_nettype none
module core_top (
	clk,
	rst,
	imem_addr,
	imem_rdata,
	dmem_addr,
	dmem_wdata,
	dmem_be,
	dmem_we,
	dmem_re,
	dmem_rdata,
	dbg_halt_req,
	dbg_halted
);
	reg _sv2v_0;
	parameter [31:0] RESET_PC = 32'h00000000;
	parameter [0:0] ENABLE_BP = 1'b1;
	parameter [0:0] ENABLE_M = 1'b1;
	input wire clk;
	input wire rst;
	output wire [31:0] imem_addr;
	input wire [31:0] imem_rdata;
	output wire [31:0] dmem_addr;
	output wire [31:0] dmem_wdata;
	output wire [3:0] dmem_be;
	output wire dmem_we;
	output wire dmem_re;
	input wire [31:0] dmem_rdata;
	input wire dbg_halt_req;
	output wire dbg_halted;
	wire stall;
	wire bubble_x;
	wire flush;
	reg [31:0] pc_f1;
	wire [31:0] pc_next;
	wire [31:0] redirect_pc;
	wire redirect;
	wire pred_taken_f1;
	wire [31:0] pred_target_f1;
	reg halt_ff1;
	reg halt_ff2;
	always @(posedge clk)
		if (rst) begin
			halt_ff1 <= 1'b0;
			halt_ff2 <= 1'b0;
		end
		else begin
			halt_ff1 <= dbg_halt_req === 1'b1;
			halt_ff2 <= halt_ff1;
		end
	wire halt = halt_ff2;
	assign pc_next = (rst ? RESET_PC : (halt ? pc_f1 : (redirect ? redirect_pc : (stall ? pc_f1 : (ENABLE_BP && pred_taken_f1 ? pred_target_f1 : pc_f1 + 32'd4)))));
	always @(posedge clk)
		if (rst)
			pc_f1 <= RESET_PC;
		else
			pc_f1 <= pc_next;
	assign imem_addr = pc_next;
	reg [31:0] pc_f2;
	reg valid_f2;
	reg pred_taken_f2;
	reg [31:0] inst_f2;
	always @(posedge clk)
		if (rst || redirect) begin
			valid_f2 <= 1'b0;
			pred_taken_f2 <= 1'b0;
		end
		else if (!stall && !halt) begin
			pc_f2 <= pc_f1;
			inst_f2 <= imem_rdata;
			valid_f2 <= 1'b1;
			pred_taken_f2 <= ENABLE_BP && pred_taken_f1;
		end
	reg [31:0] pc_d;
	reg [31:0] inst_d;
	reg valid_d;
	reg pred_taken_d;
	always @(posedge clk)
		if (rst || redirect)
			valid_d <= 1'b0;
		else if (!stall) begin
			pc_d <= pc_f2;
			inst_d <= inst_f2;
			valid_d <= valid_f2;
			pred_taken_d <= pred_taken_f2;
		end
	wire [24:0] ctrl_d;
	control_unit #(.ENABLE_M(ENABLE_M)) u_ctrl(
		.inst(inst_d),
		.ctrl(ctrl_d)
	);
	wire [4:0] rs1_d = inst_d[19:15];
	wire [4:0] rs2_d = inst_d[24:20];
	wire [4:0] rd_d = inst_d[11:7];
	wire [31:0] imm_d;
	imm_gen u_imm(
		.inst(inst_d),
		.sel(ctrl_d[14-:3]),
		.imm(imm_d)
	);
	wire rf_we_w;
	wire [4:0] rd_w;
	reg [31:0] wb_data_w;
	wire [31:0] rf_rdata1;
	wire [31:0] rf_rdata2;
	reg_file u_rf(
		.clk(clk),
		.we(rf_we_w),
		.waddr(rd_w),
		.wdata(wb_data_w),
		.raddr1(rs1_d),
		.raddr2(rs2_d),
		.rdata1(rf_rdata1),
		.rdata2(rf_rdata2)
	);
	localparam [6:0] asicirific_pkg_OPC_AUIPC = 7'b0010111;
	localparam [6:0] asicirific_pkg_OPC_LUI = 7'b0110111;
	wire uses_rs1_d = ((ctrl_d[24] && !ctrl_d[10]) && (inst_d[6:0] != asicirific_pkg_OPC_LUI)) && (inst_d[6:0] != asicirific_pkg_OPC_AUIPC);
	localparam [6:0] asicirific_pkg_OPC_OP = 7'b0110011;
	wire uses_rs2_d = (ctrl_d[11] || ctrl_d[7]) || (inst_d[6:0] == asicirific_pkg_OPC_OP);
	reg [24:0] ctrl_x;
	reg [31:0] pc_x;
	reg [31:0] imm_x;
	reg [31:0] rs1v_x;
	reg [31:0] rs2v_x;
	reg [4:0] rs1_x;
	reg [4:0] rs2_x;
	reg [4:0] rd_x;
	reg [11:0] csr_addr_x;
	reg valid_x;
	reg pred_taken_x;
	always @(posedge clk)
		if (((rst || redirect) || bubble_x) || (stall && !bubble_x)) begin
			if ((rst || redirect) || bubble_x) begin
				valid_x <= 1'b0;
				ctrl_x <= 1'sb0;
			end
		end
		else begin
			ctrl_x <= (valid_d ? ctrl_d : {25 {1'sb0}});
			valid_x <= valid_d;
			pc_x <= pc_d;
			imm_x <= imm_d;
			rs1v_x <= rf_rdata1;
			rs2v_x <= rf_rdata2;
			rs1_x <= rs1_d;
			rs2_x <= rs2_d;
			rd_x <= (valid_d && ctrl_d[23] ? rd_d : 5'd0);
			csr_addr_x <= inst_d[31:20];
			pred_taken_x <= pred_taken_d;
		end
	wire [1:0] fwd_a;
	wire [1:0] fwd_b;
	wire [4:0] rd_m;
	wire rf_we_m;
	wire is_load_m;
	wire [31:0] alu_m;
	forwarding_unit u_fwd(
		.rs1_x(rs1_x),
		.rs2_x(rs2_x),
		.rd_m(rd_m),
		.rf_we_m(rf_we_m),
		.is_load_m(is_load_m),
		.rd_w(rd_w),
		.rf_we_w(rf_we_w),
		.fwd_a(fwd_a),
		.fwd_b(fwd_b)
	);
	wire [31:0] op_a_fwd;
	wire [31:0] op_b_fwd;
	assign op_a_fwd = (fwd_a == 2'b01 ? alu_m : (fwd_a == 2'b10 ? wb_data_w : rs1v_x));
	assign op_b_fwd = (fwd_b == 2'b01 ? alu_m : (fwd_b == 2'b10 ? wb_data_w : rs2v_x));
	wire [31:0] alu_a;
	wire [31:0] alu_b;
	wire [31:0] alu_y;
	assign alu_a = (ctrl_x[16] ? pc_x : op_a_fwd);
	assign alu_b = (ctrl_x[15] ? imm_x : op_b_fwd);
	alu u_alu(
		.a(alu_a),
		.b(alu_b),
		.op(ctrl_x[20-:4]),
		.y(alu_y)
	);
	wire [2:0] cmp;
	branch_comp u_bc(
		.rs1(op_a_fwd),
		.rs2(op_b_fwd),
		.cmp(cmp)
	);
	reg br_taken;
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (ctrl_x[6-:3])
			3'b000: br_taken = cmp[2];
			3'b001: br_taken = ~cmp[2];
			3'b100: br_taken = cmp[1];
			3'b101: br_taken = ~cmp[1];
			3'b110: br_taken = cmp[0];
			3'b111: br_taken = ~cmp[0];
			default: br_taken = 1'b0;
		endcase
	end
	wire taken_x;
	wire [31:0] target_x;
	assign taken_x = valid_x && (((ctrl_x[11] && br_taken) || ctrl_x[10]) || ctrl_x[9]);
	assign target_x = (ctrl_x[9] ? (op_a_fwd + imm_x) & ~32'd1 : pc_x + imm_x);
	assign redirect = (valid_x && (taken_x != pred_taken_x)) && ((ctrl_x[11] || ctrl_x[10]) || ctrl_x[9]);
	assign redirect_pc = (taken_x ? target_x : pc_x + 32'd4);
	wire [31:0] mul_y;
	generate
		if (ENABLE_M) begin : g_mul
			mul_unit u_mul(
				.a(op_a_fwd),
				.b(op_b_fwd),
				.funct3(ctrl_x[6-:3]),
				.y(mul_y)
			);
		end
		else begin : g_nomul
			assign mul_y = 32'd0;
		end
	endgenerate
	wire div_busy;
	wire div_done;
	reg div_started_q;
	wire [31:0] div_y;
	wire div_req = valid_x && ctrl_x[0];
	wire div_start = ((div_req && !div_started_q) && !div_busy) && !div_done;
	always @(posedge clk)
		if (rst)
			div_started_q <= 1'b0;
		else if (div_start)
			div_started_q <= 1'b1;
		else if (!stall)
			div_started_q <= 1'b0;
	generate
		if (ENABLE_M) begin : g_div
			div_unit u_div(
				.clk(clk),
				.rst(rst),
				.start(div_start),
				.a(op_a_fwd),
				.b(op_b_fwd),
				.funct3(ctrl_x[6-:3]),
				.busy(div_busy),
				.done(div_done),
				.y(div_y)
			);
		end
		else begin : g_nodiv
			assign div_busy = 1'b0;
			assign div_done = 1'b1;
			assign div_y = 32'd0;
		end
	endgenerate
	wire [31:0] csr_rval;
	wire csr_en = (valid_x && ctrl_x[3]) && !stall;
	wire [31:0] csr_wval = (ctrl_x[2] ? {27'd0, rs1_x} : op_a_fwd);
	csr_file u_csr(
		.clk(clk),
		.rst(rst),
		.en(csr_en),
		.addr(csr_addr_x),
		.funct3(ctrl_x[6-:3]),
		.wval(csr_wval),
		.rval(csr_rval),
		.instret_pulse(valid_x && !stall)
	);
	wire [31:0] xres;
	assign xres = (ctrl_x[1] ? mul_y : (ctrl_x[0] ? div_y : (ctrl_x[3] ? csr_rval : alu_y)));
	wire [31:0] st_wdata;
	wire [3:0] st_be;
	store_unit u_st(
		.wdata_in(op_b_fwd),
		.addr_lo(alu_y[1:0]),
		.funct3(ctrl_x[6-:3]),
		.wdata_out(st_wdata),
		.be(st_be)
	);
	hazard_unit u_hz(
		.rs1_d(rs1_d),
		.rs2_d(rs2_d),
		.uses_rs1_d(valid_d && uses_rs1_d),
		.uses_rs2_d(valid_d && uses_rs2_d),
		.rd_x(rd_x),
		.mem_read_x(valid_x && ctrl_x[8]),
		.div_busy(div_req && !div_done),
		.stall(stall),
		.bubble_x(bubble_x)
	);
	reg [24:0] ctrl_m;
	reg [31:0] pc_m;
	reg [31:0] xres_m;
	reg [31:0] st_wdata_m;
	reg [3:0] st_be_m;
	reg valid_m;
	reg [4:0] rd_m_q;
	always @(posedge clk)
		if (rst) begin
			valid_m <= 1'b0;
			ctrl_m <= 1'sb0;
		end
		else if (stall && !bubble_x) begin
			valid_m <= 1'b0;
			ctrl_m <= 1'sb0;
		end
		else begin
			ctrl_m <= (valid_x ? ctrl_x : {25 {1'sb0}});
			valid_m <= valid_x;
			pc_m <= pc_x;
			xres_m <= xres;
			st_wdata_m <= st_wdata;
			st_be_m <= st_be;
			rd_m_q <= rd_x;
		end
	assign rd_m = (valid_m ? rd_m_q : 5'd0);
	assign rf_we_m = valid_m && ctrl_m[23];
	assign is_load_m = valid_m && ctrl_m[8];
	assign alu_m = xres_m;
	assign dmem_addr = {xres_m[31:2], 2'b00};
	assign dmem_wdata = st_wdata_m;
	assign dmem_be = st_be_m;
	assign dmem_we = valid_m && ctrl_m[7];
	assign dmem_re = valid_m && ctrl_m[8];
	reg [24:0] ctrl_w;
	reg [31:0] pc_w;
	reg [31:0] xres_w;
	reg [1:0] addr_lo_w;
	reg valid_w;
	reg [4:0] rd_w_q;
	always @(posedge clk)
		if (rst) begin
			valid_w <= 1'b0;
			ctrl_w <= 1'sb0;
		end
		else begin
			ctrl_w <= (valid_m ? ctrl_m : {25 {1'sb0}});
			valid_w <= valid_m;
			pc_w <= pc_m;
			xres_w <= xres_m;
			addr_lo_w <= xres_m[1:0];
			rd_w_q <= rd_m_q;
		end
	wire [31:0] ld_data_w;
	load_unit u_ld(
		.rdata(dmem_rdata),
		.addr_lo(addr_lo_w),
		.funct3(ctrl_w[6-:3]),
		.out(ld_data_w)
	);
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (ctrl_w[22-:2])
			2'd0: wb_data_w = xres_w;
			2'd1: wb_data_w = ld_data_w;
			2'd2: wb_data_w = pc_w + 32'd4;
			2'd3: wb_data_w = xres_w;
			default: wb_data_w = xres_w;
		endcase
	end
	assign rd_w = (valid_w && ctrl_w[23] ? rd_w_q : 5'd0);
	assign rf_we_w = valid_w && ctrl_w[23];
	generate
		if (ENABLE_BP) begin : g_bp
			bp_top u_bp(
				.clk(clk),
				.rst(rst),
				.pc_if(pc_f1),
				.pred_taken(pred_taken_f1),
				.pred_target(pred_target_f1),
				.upd_valid((valid_x && ((ctrl_x[11] || ctrl_x[10]) || ctrl_x[9])) && !stall),
				.upd_pc(pc_x),
				.upd_taken(taken_x),
				.upd_target(target_x),
				.ras_push(1'b0),
				.ras_push_addr(32'd0),
				.ras_pop(1'b0)
			);
		end
		else begin : g_nobp
			assign pred_taken_f1 = 1'b0;
			assign pred_target_f1 = 32'd0;
		end
	endgenerate
	assign dbg_halted = dbg_halt_req;
	initial _sv2v_0 = 0;
endmodule
`default_nettype none
module csr_file (
	clk,
	rst,
	en,
	addr,
	funct3,
	wval,
	rval,
	instret_pulse
);
	reg _sv2v_0;
	input wire clk;
	input wire rst;
	input wire en;
	input wire [11:0] addr;
	input wire [2:0] funct3;
	input wire [31:0] wval;
	output reg [31:0] rval;
	input wire instret_pulse;
	localparam [11:0] A_MSTATUS = 12'h300;
	localparam [11:0] A_MIE = 12'h304;
	localparam [11:0] A_MTVEC = 12'h305;
	localparam [11:0] A_MSCRATCH = 12'h340;
	localparam [11:0] A_MEPC = 12'h341;
	localparam [11:0] A_MCAUSE = 12'h342;
	localparam [11:0] A_MIP = 12'h344;
	localparam [11:0] A_MCYCLE = 12'hb00;
	localparam [11:0] A_MCYCLEH = 12'hb80;
	localparam [11:0] A_MINSTRET = 12'hb02;
	localparam [11:0] A_MINSTRETH = 12'hb82;
	reg [31:0] mstatus_q;
	reg [31:0] mie_q;
	reg [31:0] mtvec_q;
	reg [31:0] mscratch_q;
	reg [31:0] mepc_q;
	reg [31:0] mcause_q;
	reg [31:0] mip_q;
	reg [63:0] mcycle_q;
	reg [63:0] minstret_q;
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (addr)
			A_MSTATUS: rval = mstatus_q;
			A_MIE: rval = mie_q;
			A_MTVEC: rval = mtvec_q;
			A_MSCRATCH: rval = mscratch_q;
			A_MEPC: rval = mepc_q;
			A_MCAUSE: rval = mcause_q;
			A_MIP: rval = mip_q;
			A_MCYCLE: rval = mcycle_q[31:0];
			A_MCYCLEH: rval = mcycle_q[63:32];
			A_MINSTRET: rval = minstret_q[31:0];
			A_MINSTRETH: rval = minstret_q[63:32];
			default: rval = 32'd0;
		endcase
	end
	reg [31:0] newval;
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (funct3[1:0])
			2'b01: newval = wval;
			2'b10: newval = rval | wval;
			2'b11: newval = rval & ~wval;
			default: newval = rval;
		endcase
	end
	always @(posedge clk)
		if (rst) begin
			mstatus_q <= 32'd0;
			mie_q <= 32'd0;
			mtvec_q <= 32'd0;
			mscratch_q <= 32'd0;
			mepc_q <= 32'd0;
			mcause_q <= 32'd0;
			mip_q <= 32'd0;
			mcycle_q <= 64'd0;
			minstret_q <= 64'd0;
		end
		else begin
			mcycle_q <= mcycle_q + 64'd1;
			if (instret_pulse)
				minstret_q <= minstret_q + 64'd1;
			if (en)
				(* full_case, parallel_case *)
				case (addr)
					A_MSTATUS: mstatus_q <= newval;
					A_MIE: mie_q <= newval;
					A_MTVEC: mtvec_q <= newval;
					A_MSCRATCH: mscratch_q <= newval;
					A_MEPC: mepc_q <= newval;
					A_MCAUSE: mcause_q <= newval;
					default:
						;
				endcase
		end
	initial _sv2v_0 = 0;
endmodule
`default_nettype none
module debug_top (
	tck,
	tms,
	tdi,
	trst_n,
	tdo,
	tdo_oe,
	halt_req,
	halted,
	sb_re,
	sb_we,
	sb_addr,
	sb_wdata,
	sb_rdata
);
	input wire tck;
	input wire tms;
	input wire tdi;
	input wire trst_n;
	output wire tdo;
	output wire tdo_oe;
	output wire halt_req;
	input wire halted;
	output wire sb_re;
	output wire sb_we;
	output wire [31:0] sb_addr;
	output wire [31:0] sb_wdata;
	input wire [31:0] sb_rdata;
	wire dmi_capture;
	wire dmi_shift;
	wire dmi_update;
	wire dmi_tdi_w;
	wire dmi_tdo_w;
	wire req_valid;
	wire [6:0] req_addr;
	wire [31:0] req_wdata;
	wire [1:0] req_op;
	wire rsp_valid;
	wire [31:0] rsp_rdata;
	wire [1:0] rsp_status;
	wire [4:0] tap_ir;
	jtag_tap u_tap(
		.tck(tck),
		.tms(tms),
		.tdi(tdi),
		.trst_n(trst_n),
		.tdo(tdo),
		.tdo_oe(tdo_oe),
		.dmi_capture(dmi_capture),
		.dmi_shift(dmi_shift),
		.dmi_update(dmi_update),
		.dmi_tdi(dmi_tdi_w),
		.dmi_tdo(dmi_tdo_w),
		.ir_out(tap_ir)
	);
	wire sel_dtmcs = tap_ir == 5'h10;
	wire sel_dmi = tap_ir == 5'h11;
	riscv_dtm u_dtm(
		.tck(tck),
		.trst_n(trst_n),
		.dmi_capture(dmi_capture),
		.dmi_shift(dmi_shift),
		.dmi_update(dmi_update),
		.dmi_tdi(dmi_tdi_w),
		.dmi_tdo(dmi_tdo_w),
		.sel_dtmcs(sel_dtmcs),
		.sel_dmi(sel_dmi),
		.req_valid(req_valid),
		.req_addr(req_addr),
		.req_wdata(req_wdata),
		.req_op(req_op),
		.rsp_valid(rsp_valid),
		.rsp_rdata(rsp_rdata),
		.rsp_status(rsp_status)
	);
	riscv_dm u_dm(
		.clk(tck),
		.rst(~trst_n),
		.req_valid(req_valid),
		.req_addr(req_addr),
		.req_wdata(req_wdata),
		.req_op(req_op),
		.rsp_valid(rsp_valid),
		.rsp_rdata(rsp_rdata),
		.rsp_status(rsp_status),
		.halt_req(halt_req),
		.halted(halted),
		.sb_re(sb_re),
		.sb_we(sb_we),
		.sb_addr(sb_addr),
		.sb_wdata(sb_wdata),
		.sb_rdata(sb_rdata)
	);
endmodule
`default_nettype none
module div_unit (
	clk,
	rst,
	start,
	a,
	b,
	funct3,
	busy,
	done,
	y
);
	input wire clk;
	input wire rst;
	input wire start;
	input wire [31:0] a;
	input wire [31:0] b;
	input wire [2:0] funct3;
	output wire busy;
	output reg done;
	output reg [31:0] y;
	reg is_signed;
	reg want_rem;
	reg neg_q;
	reg neg_r;
	reg [31:0] ua;
	reg [31:0] ub;
	reg [31:0] quo;
	reg [32:0] rem;
	reg [5:0] cnt;
	reg running;
	assign busy = running;
	always @(posedge clk) begin
		done <= 1'b0;
		if (rst)
			running <= 1'b0;
		else if (start && !running) begin
			is_signed <= ~funct3[0];
			want_rem <= funct3[1];
			if (b == 32'd0) begin
				y <= (funct3[1] ? a : 32'hffffffff);
				done <= 1'b1;
			end
			else if ((~funct3[0] && (a == 32'h80000000)) && (b == 32'hffffffff)) begin
				y <= (funct3[1] ? 32'd0 : 32'h80000000);
				done <= 1'b1;
			end
			else begin
				neg_q <= ~funct3[0] && (a[31] ^ b[31]);
				neg_r <= ~funct3[0] && a[31];
				ua <= (~funct3[0] && a[31] ? ~a + 32'd1 : a);
				ub <= (~funct3[0] && b[31] ? ~b + 32'd1 : b);
				quo <= 32'd0;
				rem <= 33'd0;
				cnt <= 6'd32;
				running <= 1'b1;
			end
		end
		else if (running) begin : sv2v_autoblock_1
			reg [32:0] r_shift;
			reg [32:0] r_sub;
			r_shift = {rem[31:0], ua[31]};
			r_sub = r_shift - {1'b0, ub};
			ua <= {ua[30:0], 1'b0};
			if (!r_sub[32]) begin
				rem <= r_sub;
				quo <= {quo[30:0], 1'b1};
			end
			else begin
				rem <= r_shift;
				quo <= {quo[30:0], 1'b0};
			end
			cnt <= cnt - 6'd1;
			if (cnt == 6'd1) begin : sv2v_autoblock_2
				reg [31:0] rem_f;
				reg [31:0] quo_f;
				if (!r_sub[32]) begin
					rem_f = r_sub[31:0];
					quo_f = {quo[30:0], 1'b1};
				end
				else begin
					rem_f = r_shift[31:0];
					quo_f = {quo[30:0], 1'b0};
				end
				running <= 1'b0;
				done <= 1'b1;
				if (want_rem)
					y <= (neg_r ? ~rem_f + 32'd1 : rem_f);
				else
					y <= (neg_q ? ~quo_f + 32'd1 : quo_f);
			end
		end
	end
endmodule
`default_nettype none
module forwarding_unit (
	rs1_x,
	rs2_x,
	rd_m,
	rf_we_m,
	is_load_m,
	rd_w,
	rf_we_w,
	fwd_a,
	fwd_b
);
	reg _sv2v_0;
	input wire [4:0] rs1_x;
	input wire [4:0] rs2_x;
	input wire [4:0] rd_m;
	input wire rf_we_m;
	input wire is_load_m;
	input wire [4:0] rd_w;
	input wire rf_we_w;
	output reg [1:0] fwd_a;
	output reg [1:0] fwd_b;
	always @(*) begin
		if (_sv2v_0)
			;
		fwd_a = 2'b00;
		fwd_b = 2'b00;
		if (((rf_we_m && !is_load_m) && (rd_m != 5'd0)) && (rd_m == rs1_x))
			fwd_a = 2'b01;
		else if ((rf_we_w && (rd_w != 5'd0)) && (rd_w == rs1_x))
			fwd_a = 2'b10;
		if (((rf_we_m && !is_load_m) && (rd_m != 5'd0)) && (rd_m == rs2_x))
			fwd_b = 2'b01;
		else if ((rf_we_w && (rd_w != 5'd0)) && (rd_w == rs2_x))
			fwd_b = 2'b10;
	end
	initial _sv2v_0 = 0;
endmodule
`default_nettype none
module gpio (
	clk,
	rst,
	addr,
	wdata,
	we,
	rdata,
	gpio_out,
	gpio_in,
	gpio_oe
);
	reg _sv2v_0;
	input wire clk;
	input wire rst;
	input wire [3:0] addr;
	input wire [31:0] wdata;
	input wire we;
	output reg [31:0] rdata;
	output reg [7:0] gpio_out;
	input wire [7:0] gpio_in;
	output reg [7:0] gpio_oe;
	reg [7:0] in_m;
	reg [7:0] in_s;
	always @(posedge clk) begin
		in_m <= gpio_in;
		in_s <= in_m;
		if (rst) begin
			gpio_out <= 8'd0;
			gpio_oe <= 8'd0;
		end
		else if (we)
			(* full_case, parallel_case *)
			case (addr)
				4'h0: gpio_out <= wdata[7:0];
				4'h8: gpio_oe <= wdata[7:0];
				default:
					;
			endcase
	end
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (addr)
			4'h0: rdata = {24'd0, gpio_out};
			4'h4: rdata = {24'd0, in_s};
			4'h8: rdata = {24'd0, gpio_oe};
			default: rdata = 32'd0;
		endcase
	end
	initial _sv2v_0 = 0;
endmodule
`default_nettype none
module gshare_predictor (
	clk,
	rst,
	pc_if,
	pred_taken,
	upd_valid,
	upd_pc,
	upd_taken
);
	parameter [31:0] HIST_BITS = 8;
	parameter [31:0] IDX_BITS = 10;
	input wire clk;
	input wire rst;
	input wire [31:0] pc_if;
	output wire pred_taken;
	input wire upd_valid;
	input wire [31:0] upd_pc;
	input wire upd_taken;
	localparam [31:0] ENTRIES = 1 << IDX_BITS;
	reg [1:0] pht [ENTRIES - 1:0];
	reg [HIST_BITS - 1:0] ghr;
	function automatic [IDX_BITS - 1:0] idx_of;
		input reg [31:0] pc;
		input reg [HIST_BITS - 1:0] hist;
		reg [IDX_BITS - 1:0] pc_part;
		reg [IDX_BITS - 1:0] h_part;
		begin
			pc_part = pc[IDX_BITS + 1:2];
			h_part = {{IDX_BITS - HIST_BITS {1'b0}}, hist};
			idx_of = pc_part ^ h_part;
		end
	endfunction
	assign pred_taken = pht[idx_of(pc_if, ghr)][1];
	always @(posedge clk)
		if (rst) begin
			ghr <= 1'sb0;
			begin : sv2v_autoblock_1
				reg signed [31:0] i;
				for (i = 0; i < ENTRIES; i = i + 1)
					pht[i] <= 2'b01;
			end
		end
		else if (upd_valid) begin : sv2v_autoblock_2
			reg [IDX_BITS - 1:0] ui;
			ui = idx_of(upd_pc, ghr);
			if (upd_taken && (pht[ui] != 2'b11))
				pht[ui] <= pht[ui] + 2'd1;
			if (!upd_taken && (pht[ui] != 2'b00))
				pht[ui] <= pht[ui] - 2'd1;
			ghr <= {ghr[HIST_BITS - 2:0], upd_taken};
		end
endmodule
`default_nettype none
module hazard_unit (
	rs1_d,
	rs2_d,
	uses_rs1_d,
	uses_rs2_d,
	rd_x,
	mem_read_x,
	div_busy,
	stall,
	bubble_x
);
	reg _sv2v_0;
	input wire [4:0] rs1_d;
	input wire [4:0] rs2_d;
	input wire uses_rs1_d;
	input wire uses_rs2_d;
	input wire [4:0] rd_x;
	input wire mem_read_x;
	input wire div_busy;
	output reg stall;
	output reg bubble_x;
	reg load_use;
	always @(*) begin
		if (_sv2v_0)
			;
		load_use = (mem_read_x && (rd_x != 5'd0)) && ((uses_rs1_d && (rd_x == rs1_d)) || (uses_rs2_d && (rd_x == rs2_d)));
		stall = load_use || div_busy;
		bubble_x = load_use;
	end
	initial _sv2v_0 = 0;
endmodule
`default_nettype none
module imm_gen (
	inst,
	sel,
	imm
);
	reg _sv2v_0;
	input wire [31:0] inst;
	input wire [2:0] sel;
	output reg [31:0] imm;
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (sel)
			3'd0: imm = {{21 {inst[31]}}, inst[30:20]};
			3'd1: imm = {{21 {inst[31]}}, inst[30:25], inst[11:7]};
			3'd2: imm = {{20 {inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};
			3'd3: imm = {inst[31:12], 12'd0};
			3'd4: imm = {{12 {inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0};
			default: imm = 32'd0;
		endcase
	end
	initial _sv2v_0 = 0;
endmodule
`default_nettype none
module jtag_tap (
	tck,
	tms,
	tdi,
	trst_n,
	tdo,
	tdo_oe,
	dmi_capture,
	dmi_shift,
	dmi_update,
	dmi_tdi,
	dmi_tdo,
	ir_out
);
	reg _sv2v_0;
	parameter [31:0] IDCODE_VAL = 32'h1a51c1d1;
	parameter [31:0] IR_BITS = 5;
	parameter [31:0] DMI_BITS = 41;
	input wire tck;
	input wire tms;
	input wire tdi;
	input wire trst_n;
	output reg tdo;
	output reg tdo_oe;
	output wire dmi_capture;
	output wire dmi_shift;
	output wire dmi_update;
	output wire dmi_tdi;
	input wire dmi_tdo;
	output wire [4:0] ir_out;
	reg [IR_BITS - 1:0] ir;
	assign ir_out = ir;
	localparam [IR_BITS - 1:0] IR_IDCODE = 5'h01;
	localparam [IR_BITS - 1:0] IR_DTMCS = 5'h10;
	localparam [IR_BITS - 1:0] IR_DMI = 5'h11;
	localparam [IR_BITS - 1:0] IR_BYPASS = 5'h1f;
	reg [3:0] st;
	always @(posedge tck or negedge trst_n)
		if (!trst_n)
			st <= 4'd0;
		else
			(* full_case, parallel_case *)
			case (st)
				4'd0: st <= (tms ? 4'd0 : 4'd1);
				4'd1: st <= (tms ? 4'd2 : 4'd1);
				4'd2: st <= (tms ? 4'd9 : 4'd3);
				4'd3: st <= (tms ? 4'd5 : 4'd4);
				4'd4: st <= (tms ? 4'd5 : 4'd4);
				4'd5: st <= (tms ? 4'd8 : 4'd6);
				4'd6: st <= (tms ? 4'd7 : 4'd6);
				4'd7: st <= (tms ? 4'd8 : 4'd4);
				4'd8: st <= (tms ? 4'd2 : 4'd1);
				4'd9: st <= (tms ? 4'd0 : 4'd10);
				4'd10: st <= (tms ? 4'd12 : 4'd11);
				4'd11: st <= (tms ? 4'd12 : 4'd11);
				4'd12: st <= (tms ? 4'd15 : 4'd13);
				4'd13: st <= (tms ? 4'd14 : 4'd13);
				4'd14: st <= (tms ? 4'd15 : 4'd11);
				4'd15: st <= (tms ? 4'd2 : 4'd1);
				default: st <= 4'd0;
			endcase
	reg [IR_BITS - 1:0] ir_shift;
	always @(posedge tck or negedge trst_n)
		if (!trst_n) begin
			ir_shift <= IR_IDCODE;
			ir <= IR_IDCODE;
		end
		else
			(* full_case, parallel_case *)
			case (st)
				4'd0: ir <= IR_IDCODE;
				4'd10: ir_shift <= {{IR_BITS - 2 {1'b0}}, 2'b01};
				4'd11: ir_shift <= {tdi, ir_shift[IR_BITS - 1:1]};
				4'd15: ir <= ir_shift;
				default:
					;
			endcase
	reg [31:0] idcode_shift;
	reg bypass_bit;
	always @(posedge tck)
		(* full_case, parallel_case *)
		case (st)
			4'd3: begin
				idcode_shift <= IDCODE_VAL;
				bypass_bit <= 1'b0;
			end
			4'd4: begin
				idcode_shift <= {tdi, idcode_shift[31:1]};
				bypass_bit <= tdi;
			end
			default:
				;
		endcase
	assign dmi_capture = (st == 4'd3) && ((ir == IR_DMI) || (ir == IR_DTMCS));
	assign dmi_shift = (st == 4'd4) && ((ir == IR_DMI) || (ir == IR_DTMCS));
	assign dmi_update = (st == 4'd8) && ((ir == IR_DMI) || (ir == IR_DTMCS));
	assign dmi_tdi = tdi;
	reg tdo_next;
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (st)
			4'd11: tdo_next = ir_shift[0];
			4'd4:
				(* full_case, parallel_case *)
				case (ir)
					IR_IDCODE: tdo_next = idcode_shift[0];
					IR_DMI, IR_DTMCS: tdo_next = dmi_tdo;
					default: tdo_next = bypass_bit;
				endcase
			default: tdo_next = 1'b0;
		endcase
	end
	always @(negedge tck) begin
		tdo <= tdo_next;
		tdo_oe <= (st == 4'd11) || (st == 4'd4);
	end
	initial _sv2v_0 = 0;
endmodule
`default_nettype none
module load_unit (
	rdata,
	addr_lo,
	funct3,
	out
);
	reg _sv2v_0;
	input wire [31:0] rdata;
	input wire [1:0] addr_lo;
	input wire [2:0] funct3;
	output reg [31:0] out;
	reg [7:0] b;
	reg [15:0] h;
	always @(*) begin
		if (_sv2v_0)
			;
		b = rdata[8 * addr_lo+:8];
		h = (addr_lo[1] ? rdata[31:16] : rdata[15:0]);
		(* full_case, parallel_case *)
		case (funct3)
			3'b000: out = {{24 {b[7]}}, b};
			3'b001: out = {{16 {h[15]}}, h};
			3'b010: out = rdata;
			3'b100: out = {24'd0, b};
			3'b101: out = {16'd0, h};
			default: out = rdata;
		endcase
	end
	initial _sv2v_0 = 0;
endmodule
`default_nettype none
module main_soc (
	clk,
	rst,
	uart_tx,
	uart_rx,
	gpio_out,
	gpio_in,
	gpio_oe,
	tck,
	tms,
	tdi,
	trst_n,
	tdo,
	tdo_oe,
	boot_sel,
	boot_active,
	boot_done
);
	reg _sv2v_0;
	parameter [31:0] RAM_WORDS = 64;
	parameter [0:0] RV32M = 1'b1;
	input wire clk;
	input wire rst;
	output wire uart_tx;
	input wire uart_rx;
	output wire [7:0] gpio_out;
	input wire [7:0] gpio_in;
	output wire [7:0] gpio_oe;
	input wire tck;
	input wire tms;
	input wire tdi;
	input wire trst_n;
	output wire tdo;
	output wire tdo_oe;
	input wire boot_sel;
	output wire boot_active;
	output wire boot_done;
	localparam signed [31:0] AW = $clog2(RAM_WORDS);
	wire [31:0] imem_addr;
	wire [31:0] imem_rdata;
	wire [31:0] dmem_addr;
	wire [31:0] dmem_wdata;
	reg [31:0] dmem_rdata;
	wire [3:0] dmem_be;
	wire dmem_we;
	wire dmem_re;
	wire dbg_halt_req;
	wire dbg_halted;
	reg booted;
	reg [3:0] settle;
	reg core_run;
	always @(posedge clk)
		if (rst) begin
			booted <= ~boot_sel;
			settle <= 4'd8;
			core_run <= 1'b0;
		end
		else begin
			if (boot_done)
				booted <= 1'b1;
			if (booted) begin
				if (settle != 4'd0)
					settle <= settle - 4'd1;
				else
					core_run <= 1'b1;
			end
		end
	wire core_released = core_run;
	wire core_rst = rst || !core_run;
	core_top #(
		.RESET_PC(32'h10000000),
		.ENABLE_BP(1'b0),
		.ENABLE_M(RV32M)
	) u_core(
		.clk(clk),
		.rst(core_rst),
		.imem_addr(imem_addr),
		.imem_rdata(imem_rdata),
		.dmem_addr(dmem_addr),
		.dmem_wdata(dmem_wdata),
		.dmem_be(dmem_be),
		.dmem_we(dmem_we),
		.dmem_re(dmem_re),
		.dmem_rdata(dmem_rdata),
		.dbg_halt_req(dbg_halt_req),
		.dbg_halted(dbg_halted)
	);
	wire brx_valid;
	wire [7:0] brx_data;
	wire btx_start;
	wire btx_busy;
	wire [7:0] btx_data;
	wire boot_we;
	wire [AW - 1:0] boot_addr;
	wire [31:0] boot_wdata;
	wire btx_pin;
	wire mtx_pin;
	localparam [15:0] BOOT_DIV = 16'd217;
	uart_rx u_brx(
		.clk(clk),
		.rst(rst),
		.clk_div(BOOT_DIV),
		.rx(uart_rx),
		.valid(brx_valid),
		.data(brx_data)
	);
	uart_tx u_btx(
		.clk(clk),
		.rst(rst),
		.clk_div(BOOT_DIV),
		.start(btx_start),
		.data(btx_data),
		.busy(btx_busy),
		.tx(btx_pin)
	);
	uart_boot #(.AW(AW)) u_boot(
		.clk(clk),
		.rst(rst),
		.boot_sel(boot_sel),
		.rx_valid(brx_valid),
		.rx_data(brx_data),
		.tx_start(btx_start),
		.tx_data(btx_data),
		.tx_busy(btx_busy),
		.mem_we(boot_we),
		.mem_addr(boot_addr),
		.mem_wdata(boot_wdata),
		.boot_active(boot_active),
		.boot_done(boot_done),
		.boot_err()
	);
	assign uart_tx = (boot_active ? btx_pin : mtx_pin);
	wire sb_re;
	wire sb_we;
	wire [31:0] sb_addr;
	wire [31:0] sb_wdata;
	wire [31:0] sb_rdata;
	debug_top u_dbg(
		.tck(tck),
		.tms(tms),
		.tdi(tdi),
		.trst_n(trst_n),
		.tdo(tdo),
		.tdo_oe(tdo_oe),
		.halt_req(dbg_halt_req),
		.halted(dbg_halted),
		.sb_re(sb_re),
		.sb_we(sb_we),
		.sb_addr(sb_addr),
		.sb_wdata(sb_wdata),
		.sb_rdata(sb_rdata)
	);
	wire is_ram_d = dmem_addr[31:28] == 4'h1;
	wire is_peri_d = dmem_addr[31:16] == 16'h2000;
	wire [4:0] psel;
	bus_fabric u_fab(
		.addr(dmem_addr),
		.sel(psel)
	);
	reg [AW - 1:0] ram_addr;
	reg [31:0] ram_wdata;
	wire [31:0] ram_rdata;
	reg [3:0] ram_be;
	reg ram_we;
	wire use_dbg;
	wire use_data;
	assign use_dbg = core_released && (sb_we || sb_re);
	assign use_data = core_released && (dmem_we || (dmem_re && is_ram_d));
	always @(*) begin
		if (_sv2v_0)
			;
		if (boot_we) begin
			ram_addr = boot_addr;
			ram_wdata = boot_wdata;
			ram_be = 4'b1111;
			ram_we = 1'b1;
		end
		else if (use_dbg) begin
			ram_addr = sb_addr[AW + 1:2];
			ram_wdata = sb_wdata;
			ram_be = 4'b1111;
			ram_we = sb_we;
		end
		else if (use_data) begin
			ram_addr = dmem_addr[AW + 1:2];
			ram_wdata = dmem_wdata;
			ram_be = dmem_be;
			ram_we = dmem_we && is_ram_d;
		end
		else begin
			ram_addr = imem_addr[AW + 1:2];
			ram_wdata = 32'd0;
			ram_be = 4'b0000;
			ram_we = 1'b0;
		end
	end
	spram #(.WORDS(RAM_WORDS)) u_ram(
		.clk(clk),
		.addr(ram_addr),
		.wdata(ram_wdata),
		.be(ram_be),
		.we(ram_we),
		.rdata(ram_rdata)
	);
	reg preempt_d;
	reg preempt_q;
	always @(*) begin
		if (_sv2v_0)
			;
		preempt_d = ((use_dbg === 1'b1) || (use_data === 1'b1)) || (boot_we === 1'b1);
	end
	always @(posedge clk)
		if (rst)
			preempt_q <= 1'b1;
		else
			preempt_q <= preempt_d;
	assign imem_rdata = (preempt_q ? 32'h00000013 : ram_rdata);
	assign sb_rdata = ram_rdata;
	wire [31:0] uart_rd;
	wire [31:0] gpio_rd;
	uart u_uart(
		.clk(clk),
		.rst(rst),
		.addr(dmem_addr[3:0]),
		.wdata(dmem_wdata),
		.we(dmem_we && psel[0]),
		.re(dmem_re && psel[0]),
		.rdata(uart_rd),
		.tx(mtx_pin),
		.rx(uart_rx)
	);
	gpio u_gpio(
		.clk(clk),
		.rst(rst),
		.addr(dmem_addr[3:0]),
		.wdata(dmem_wdata),
		.we(dmem_we && psel[1]),
		.rdata(gpio_rd),
		.gpio_out(gpio_out),
		.gpio_in(gpio_in),
		.gpio_oe(gpio_oe)
	);
	reg [4:0] psel_q;
	reg is_ram_q;
	always @(posedge clk) begin
		psel_q <= psel;
		is_ram_q <= is_ram_d;
	end
	always @(*) begin
		if (_sv2v_0)
			;
		if (is_ram_q)
			dmem_rdata = ram_rdata;
		else if (psel_q[0])
			dmem_rdata = uart_rd;
		else if (psel_q[1])
			dmem_rdata = gpio_rd;
		else
			dmem_rdata = 32'd0;
	end
	initial _sv2v_0 = 0;
endmodule
`default_nettype none
module mul_unit (
	a,
	b,
	funct3,
	y
);
	reg _sv2v_0;
	input wire [31:0] a;
	input wire [31:0] b;
	input wire [2:0] funct3;
	output reg [31:0] y;
	reg signed [63:0] ss;
	reg signed [63:0] su;
	reg [63:0] uu;
	always @(*) begin
		if (_sv2v_0)
			;
		ss = $signed(a) * $signed(b);
		su = $signed(a) * $signed({1'b0, b});
		uu = a * b;
		case (funct3[1:0])
			2'b00: y = ss[31:0];
			2'b01: y = ss[63:32];
			2'b10: y = su[63:32];
			2'b11: y = uu[63:32];
			default: y = 32'd0;
		endcase
	end
	initial _sv2v_0 = 0;
endmodule
`default_nettype none
module ras (
	clk,
	rst,
	push,
	push_addr,
	pop,
	top_addr,
	top_valid
);
	parameter [31:0] DEPTH_LOG2 = 3;
	input wire clk;
	input wire rst;
	input wire push;
	input wire [31:0] push_addr;
	input wire pop;
	output wire [31:0] top_addr;
	output wire top_valid;
	localparam [31:0] DEPTH = 1 << DEPTH_LOG2;
	reg [31:0] stack [DEPTH - 1:0];
	reg [DEPTH_LOG2 - 1:0] sp;
	reg [DEPTH_LOG2:0] count;
	assign top_valid = count != {(DEPTH_LOG2 >= 0 ? DEPTH_LOG2 + 1 : 1 - DEPTH_LOG2) {1'sb0}};
	assign top_addr = stack[sp - 1'b1];
	always @(posedge clk)
		if (rst) begin
			sp <= 1'sb0;
			count <= 1'sb0;
		end
		else
			(* full_case, parallel_case *)
			case ({push, pop})
				2'b10: begin
					stack[sp] <= push_addr;
					sp <= sp + 1'b1;
					if (count != {1'b1, {DEPTH_LOG2 {1'b0}}})
						count <= count + 1'b1;
				end
				2'b01:
					if (count != {(DEPTH_LOG2 >= 0 ? DEPTH_LOG2 + 1 : 1 - DEPTH_LOG2) {1'sb0}}) begin
						sp <= sp - 1'b1;
						count <= count - 1'b1;
					end
				2'b11: stack[sp - 1'b1] <= push_addr;
				default:
					;
			endcase
endmodule
`default_nettype none
module reg_file (
	clk,
	we,
	waddr,
	wdata,
	raddr1,
	raddr2,
	rdata1,
	rdata2
);
	reg _sv2v_0;
	input wire clk;
	input wire we;
	input wire [4:0] waddr;
	input wire [31:0] wdata;
	input wire [4:0] raddr1;
	input wire [4:0] raddr2;
	output reg [31:0] rdata1;
	output reg [31:0] rdata2;
	reg [31:0] regs [31:0];
	always @(posedge clk)
		if (we && (waddr != 5'd0))
			regs[waddr] <= wdata;
	always @(*) begin
		if (_sv2v_0)
			;
		rdata1 = (raddr1 == 5'd0 ? 32'd0 : (we && (waddr == raddr1) ? wdata : regs[raddr1]));
		rdata2 = (raddr2 == 5'd0 ? 32'd0 : (we && (waddr == raddr2) ? wdata : regs[raddr2]));
	end
	initial _sv2v_0 = 0;
endmodule
`default_nettype none
module riscv_dm (
	clk,
	rst,
	req_valid,
	req_addr,
	req_wdata,
	req_op,
	rsp_valid,
	rsp_rdata,
	rsp_status,
	halt_req,
	halted,
	sb_re,
	sb_we,
	sb_addr,
	sb_wdata,
	sb_rdata
);
	parameter [31:0] ABITS = 7;
	input wire clk;
	input wire rst;
	input wire req_valid;
	input wire [ABITS - 1:0] req_addr;
	input wire [31:0] req_wdata;
	input wire [1:0] req_op;
	output reg rsp_valid;
	output reg [31:0] rsp_rdata;
	output reg [1:0] rsp_status;
	output wire halt_req;
	input wire halted;
	output reg sb_re;
	output reg sb_we;
	output reg [31:0] sb_addr;
	output reg [31:0] sb_wdata;
	input wire [31:0] sb_rdata;
	localparam [6:0] A_DMCONTROL = 7'h10;
	localparam [6:0] A_DMSTATUS = 7'h11;
	localparam [6:0] A_HARTINFO = 7'h12;
	localparam [6:0] A_SBCS = 7'h38;
	localparam [6:0] A_SBADDR0 = 7'h39;
	localparam [6:0] A_SBDATA0 = 7'h3c;
	reg dmactive_q;
	reg haltreq_q;
	reg sbautoinc_q;
	reg sbreadonaddr_q;
	reg sbreadondata_q;
	reg [31:0] sbaddr_q;
	reg [31:0] sbdata_q;
	reg sb_pending_rd_q;
	reg sb_pending2_q;
	assign halt_req = dmactive_q & haltreq_q;
	wire [31:0] dmstatus_val = {18'h00000, halted, halted, ~halted, ~halted, 8'h0a};
	wire [31:0] sbcs_val = {15'h1002, sbautoinc_q, sbreadondata_q, 15'h0407};
	always @(posedge clk) begin
		rsp_valid <= 1'b0;
		sb_re <= 1'b0;
		sb_we <= 1'b0;
		if (rst) begin
			dmactive_q <= 1'b0;
			haltreq_q <= 1'b0;
			sbautoinc_q <= 1'b0;
			sbreadonaddr_q <= 1'b0;
			sbreadondata_q <= 1'b0;
			sbaddr_q <= 32'd0;
			sbdata_q <= 32'd0;
			sb_pending_rd_q <= 1'b0;
			sb_pending2_q <= 1'b0;
			rsp_status <= 2'd0;
		end
		else begin
			sb_pending2_q <= sb_pending_rd_q;
			sb_pending_rd_q <= 1'b0;
			if (sb_pending2_q)
				sbdata_q <= sb_rdata;
			if (req_valid) begin
				rsp_valid <= 1'b1;
				rsp_status <= 2'd0;
				(* full_case, parallel_case *)
				case (req_addr)
					A_DMCONTROL: begin
						if (req_op == 2'b10) begin
							dmactive_q <= req_wdata[0];
							haltreq_q <= req_wdata[31];
							if (req_wdata[30])
								haltreq_q <= 1'b0;
						end
						rsp_rdata <= {haltreq_q, 30'd0, dmactive_q};
					end
					A_DMSTATUS: rsp_rdata <= dmstatus_val;
					A_HARTINFO: rsp_rdata <= 32'd0;
					A_SBCS: begin
						if (req_op == 2'b10) begin
							sbautoinc_q <= req_wdata[16];
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
							sb_we <= 1'b1;
							sb_addr <= sbaddr_q;
							sb_wdata <= req_wdata;
							sbdata_q <= req_wdata;
							if (sbautoinc_q)
								sbaddr_q <= sbaddr_q + 32'd4;
						end
						else if (req_op == 2'b01) begin
							rsp_rdata <= sbdata_q;
							if (sbreadondata_q) begin
								sb_re <= 1'b1;
								sb_addr <= sbaddr_q;
								sb_pending_rd_q <= 1'b1;
								if (sbautoinc_q)
									sbaddr_q <= sbaddr_q + 32'd4;
							end
						end
						if (req_op != 2'b01)
							rsp_rdata <= sbdata_q;
					end
					default: rsp_rdata <= 32'd0;
				endcase
			end
		end
	end
endmodule
`default_nettype none
module riscv_dtm (
	tck,
	trst_n,
	dmi_capture,
	dmi_shift,
	dmi_update,
	dmi_tdi,
	dmi_tdo,
	sel_dtmcs,
	sel_dmi,
	req_valid,
	req_addr,
	req_wdata,
	req_op,
	rsp_valid,
	rsp_rdata,
	rsp_status
);
	parameter [31:0] ABITS = 7;
	input wire tck;
	input wire trst_n;
	input wire dmi_capture;
	input wire dmi_shift;
	input wire dmi_update;
	input wire dmi_tdi;
	output wire dmi_tdo;
	input wire sel_dtmcs;
	input wire sel_dmi;
	output reg req_valid;
	output reg [ABITS - 1:0] req_addr;
	output reg [31:0] req_wdata;
	output reg [1:0] req_op;
	input wire rsp_valid;
	input wire [31:0] rsp_rdata;
	input wire [1:0] rsp_status;
	localparam [31:0] DMI_BITS = ABITS + 34;
	wire [31:0] dtmcs_val = {22'h000004, ABITS[5:0], 4'd1};
	reg [31:0] dtmcs_shift;
	reg [DMI_BITS - 1:0] dmi_shift_q;
	reg [31:0] cap_rdata;
	reg [1:0] cap_status;
	always @(posedge tck or negedge trst_n)
		if (!trst_n) begin
			cap_rdata <= 32'd0;
			cap_status <= 2'd0;
		end
		else if (rsp_valid) begin
			cap_rdata <= rsp_rdata;
			cap_status <= rsp_status;
		end
	always @(posedge tck)
		if (dmi_capture) begin
			dtmcs_shift <= dtmcs_val;
			dmi_shift_q <= {{ABITS {1'b0}}, cap_rdata, cap_status};
		end
		else if (dmi_shift) begin
			dtmcs_shift <= {dmi_tdi, dtmcs_shift[31:1]};
			dmi_shift_q <= {dmi_tdi, dmi_shift_q[DMI_BITS - 1:1]};
		end
	assign dmi_tdo = (sel_dtmcs ? dtmcs_shift[0] : dmi_shift_q[0]);
	always @(posedge tck or negedge trst_n)
		if (!trst_n)
			req_valid <= 1'b0;
		else begin
			req_valid <= 1'b0;
			if (dmi_update && sel_dmi) begin
				req_addr <= dmi_shift_q[DMI_BITS - 1-:ABITS];
				req_wdata <= dmi_shift_q[33:2];
				req_op <= dmi_shift_q[1:0];
				req_valid <= dmi_shift_q[1:0] != 2'b00;
			end
		end
endmodule
`default_nettype none
module spram (
	clk,
	addr,
	wdata,
	be,
	we,
	rdata
);
	parameter [31:0] WORDS = 512;
	parameter [31:0] AW = $clog2(WORDS);
	input wire clk;
	input wire [AW - 1:0] addr;
	input wire [31:0] wdata;
	input wire [3:0] be;
	input wire we;
	output reg [31:0] rdata;
	reg [31:0] mem [0:WORDS - 1];
	always @(posedge clk) begin
		if (we) begin
			if (be[0])
				mem[addr][7:0] <= wdata[7:0];
			if (be[1])
				mem[addr][15:8] <= wdata[15:8];
			if (be[2])
				mem[addr][23:16] <= wdata[23:16];
			if (be[3])
				mem[addr][31:24] <= wdata[31:24];
		end
		rdata <= mem[addr];
	end
endmodule
`default_nettype none
module store_unit (
	wdata_in,
	addr_lo,
	funct3,
	wdata_out,
	be
);
	reg _sv2v_0;
	input wire [31:0] wdata_in;
	input wire [1:0] addr_lo;
	input wire [2:0] funct3;
	output reg [31:0] wdata_out;
	output reg [3:0] be;
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (funct3[1:0])
			2'b00: begin
				wdata_out = {4 {wdata_in[7:0]}};
				be = 4'b0001 << addr_lo;
			end
			2'b01: begin
				wdata_out = {2 {wdata_in[15:0]}};
				be = (addr_lo[1] ? 4'b1100 : 4'b0011);
			end
			default: begin
				wdata_out = wdata_in;
				be = 4'b1111;
			end
		endcase
	end
	initial _sv2v_0 = 0;
endmodule
`default_nettype none
module tt_um_asicirific (
	ui_in,
	uo_out,
	uio_in,
	uio_out,
	uio_oe,
	ena,
	clk,
	rst_n
);
	input wire [7:0] ui_in;
	output wire [7:0] uo_out;
	input wire [7:0] uio_in;
	output wire [7:0] uio_out;
	output wire [7:0] uio_oe;
	input wire ena;
	input wire clk;
	input wire rst_n;
	wire rst = ~rst_n;
	wire m_uart_tx;
	wire m_tdo;
	wire m_tdo_oe;
	wire m_boot_active;
	wire m_boot_done;
	wire [7:0] m_gpio_out;
	wire [7:0] m_gpio_in;
	wire [7:0] m_gpio_oe;
	assign m_gpio_in = {5'd0, ui_in[4:2]};
	main_soc #(
		.RAM_WORDS(64),
		.RV32M(1'b0)
	) u_soc(
		.clk(clk),
		.rst(rst),
		.uart_tx(m_uart_tx),
		.uart_rx(ui_in[0]),
		.gpio_out(m_gpio_out),
		.gpio_in(m_gpio_in),
		.gpio_oe(m_gpio_oe),
		.tck(uio_in[0]),
		.tms(uio_in[1]),
		.tdi(uio_in[2]),
		.trst_n(uio_in[3]),
		.tdo(m_tdo),
		.tdo_oe(m_tdo_oe),
		.boot_sel(ui_in[1]),
		.boot_active(m_boot_active),
		.boot_done(m_boot_done)
	);
	assign uo_out[0] = m_uart_tx;
	assign uo_out[1] = m_boot_active;
	assign uo_out[2] = m_tdo;
	assign uo_out[7:3] = m_gpio_out[4:0];
	assign uio_oe = 8'b11110000;
	assign uio_out[0] = 1'b0;
	assign uio_out[1] = 1'b0;
	assign uio_out[2] = 1'b0;
	assign uio_out[3] = 1'b0;
	assign uio_out[4] = m_gpio_out[5];
	assign uio_out[5] = m_gpio_out[6];
	assign uio_out[6] = m_gpio_out[7];
	assign uio_out[7] = m_boot_done;
	wire _unused = &{ena, ui_in[7:5], m_tdo_oe, m_gpio_oe, 1'b0};
endmodule
`default_nettype none
module uart (
	clk,
	rst,
	addr,
	wdata,
	we,
	re,
	rdata,
	tx,
	rx
);
	reg _sv2v_0;
	input wire clk;
	input wire rst;
	input wire [3:0] addr;
	input wire [31:0] wdata;
	input wire we;
	input wire re;
	output reg [31:0] rdata;
	output wire tx;
	input wire rx;
	reg [15:0] clk_div;
	wire tx_busy;
	wire rx_valid;
	reg rx_avail;
	wire [7:0] rx_data;
	reg [7:0] rx_hold;
	uart_tx u_tx(
		.clk(clk),
		.rst(rst),
		.clk_div(clk_div),
		.start(we && (addr == 4'h0)),
		.data(wdata[7:0]),
		.busy(tx_busy),
		.tx(tx)
	);
	uart_rx u_rx(
		.clk(clk),
		.rst(rst),
		.clk_div(clk_div),
		.rx(rx),
		.valid(rx_valid),
		.data(rx_data)
	);
	always @(posedge clk)
		if (rst) begin
			clk_div <= 16'd217;
			rx_avail <= 1'b0;
		end
		else begin
			if (rx_valid) begin
				rx_hold <= rx_data;
				rx_avail <= 1'b1;
			end
			if (re && (addr == 4'h0))
				rx_avail <= 1'b0;
			if (we && (addr == 4'h8))
				clk_div <= wdata[15:0];
		end
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (addr)
			4'h0: rdata = {24'd0, rx_hold};
			4'h4: rdata = {30'd0, rx_avail, tx_busy};
			4'h8: rdata = {16'd0, clk_div};
			default: rdata = 32'd0;
		endcase
	end
	initial _sv2v_0 = 0;
endmodule
`default_nettype none
module uart_boot (
	clk,
	rst,
	boot_sel,
	rx_valid,
	rx_data,
	tx_start,
	tx_data,
	tx_busy,
	mem_we,
	mem_addr,
	mem_wdata,
	boot_active,
	boot_done,
	boot_err
);
	parameter [31:0] AW = 9;
	input wire clk;
	input wire rst;
	input wire boot_sel;
	input wire rx_valid;
	input wire [7:0] rx_data;
	output reg tx_start;
	output reg [7:0] tx_data;
	input wire tx_busy;
	output reg mem_we;
	output reg [AW - 1:0] mem_addr;
	output reg [31:0] mem_wdata;
	output reg boot_active;
	output reg boot_done;
	output reg boot_err;
	localparam [7:0] MAGIC0 = 8'h41;
	localparam [7:0] MAGIC1 = 8'h53;
	localparam [7:0] MAGIC2 = 8'h49;
	localparam [7:0] MAGIC3 = 8'h43;
	localparam [3:0] B_IDLE = 0;
	localparam [3:0] B_M1 = 1;
	localparam [3:0] B_M2 = 2;
	localparam [3:0] B_M3 = 3;
	localparam [3:0] B_COUNT = 4;
	localparam [3:0] B_DATA = 5;
	localparam [3:0] B_CHECK = 6;
	localparam [3:0] B_REPORT = 7;
	localparam [3:0] B_RUN = 8;
	reg [3:0] st;
	reg [1:0] bcnt;
	reg [31:0] shreg;
	reg full;
	reg [AW - 1:0] wr_word;
	reg [31:0] words_left;
	reg [31:0] checksum;
	reg [31:0] check_rx;
	reg boot_ok;
	reg [7:0] status_code;
	reg status_send;
	always @(posedge clk) begin
		mem_we <= 1'b0;
		boot_done <= 1'b0;
		boot_err <= 1'b0;
		full <= 1'b0;
		if (rst) begin
			st <= (boot_sel ? B_IDLE : B_RUN);
			boot_active <= boot_sel;
			bcnt <= 2'd0;
			wr_word <= 1'sb0;
			checksum <= 1'sb0;
		end
		else
			case (st)
				B_IDLE: begin
					boot_active <= 1'b1;
					if (rx_valid && (rx_data == MAGIC0))
						st <= B_M1;
				end
				B_M1:
					if (rx_valid)
						st <= (rx_data == MAGIC1 ? B_M2 : B_IDLE);
				B_M2:
					if (rx_valid)
						st <= (rx_data == MAGIC2 ? B_M3 : B_IDLE);
				B_M3:
					if (rx_valid) begin
						if (rx_data == MAGIC3) begin
							st <= B_COUNT;
							bcnt <= 2'd0;
						end
						else
							st <= B_IDLE;
					end
				B_COUNT: begin
					if (rx_valid) begin
						shreg <= {rx_data, shreg[31:8]};
						full <= bcnt == 2'd3;
						bcnt <= (bcnt == 2'd3 ? 2'd0 : bcnt + 2'd1);
					end
					if (full) begin
						words_left <= shreg;
						checksum <= 32'd0;
						wr_word <= 1'sb0;
						st <= B_DATA;
					end
				end
				B_DATA: begin
					if (rx_valid) begin
						shreg <= {rx_data, shreg[31:8]};
						full <= bcnt == 2'd3;
						bcnt <= (bcnt == 2'd3 ? 2'd0 : bcnt + 2'd1);
					end
					if (full) begin
						mem_we <= 1'b1;
						mem_addr <= wr_word;
						mem_wdata <= shreg;
						wr_word <= wr_word + 1'b1;
						checksum <= checksum + shreg;
						words_left <= words_left - 32'd1;
						if (words_left == 32'd1)
							st <= B_CHECK;
					end
				end
				B_CHECK: begin
					if (rx_valid) begin
						shreg <= {rx_data, shreg[31:8]};
						full <= bcnt == 2'd3;
						bcnt <= (bcnt == 2'd3 ? 2'd0 : bcnt + 2'd1);
					end
					if (full) begin
						check_rx <= shreg;
						boot_ok <= shreg == checksum;
						st <= B_REPORT;
					end
				end
				B_REPORT: begin
					status_code <= (boot_ok ? 8'h9d : 8'hee);
					status_send <= 1'b1;
					if (boot_ok) begin
						boot_done <= 1'b1;
						boot_active <= 1'b0;
						st <= B_RUN;
					end
					else begin
						boot_err <= 1'b1;
						st <= B_IDLE;
					end
				end
				B_RUN: boot_active <= 1'b0;
				default: st <= B_IDLE;
			endcase
	end
	always @(posedge clk) begin
		tx_start <= 1'b0;
		if (rst)
			status_send <= 1'b0;
		else if (status_send && !tx_busy) begin
			tx_data <= status_code;
			tx_start <= 1'b1;
			status_send <= 1'b0;
		end
	end
endmodule
`default_nettype none
module uart_rx (
	clk,
	rst,
	clk_div,
	rx,
	valid,
	data
);
	input wire clk;
	input wire rst;
	input wire [15:0] clk_div;
	input wire rx;
	output reg valid;
	output reg [7:0] data;
	reg rx_m;
	reg rx_s;
	always @(posedge clk) begin
		rx_m <= rx;
		rx_s <= rx_m;
	end
	reg [1:0] st;
	reg [15:0] cnt;
	reg [2:0] bit_idx;
	reg [7:0] sh;
	always @(posedge clk) begin
		valid <= 1'b0;
		if (rst)
			st <= 2'd0;
		else
			(* full_case, parallel_case *)
			case (st)
				2'd0:
					if (!rx_s) begin
						st <= 2'd1;
						cnt <= 16'd0;
					end
				2'd1:
					if (cnt == (clk_div >> 1)) begin
						if (!rx_s) begin
							st <= 2'd2;
							cnt <= 16'd0;
							bit_idx <= 3'd0;
						end
						else
							st <= 2'd0;
					end
					else
						cnt <= cnt + 16'd1;
				2'd2:
					if (cnt == (clk_div - 16'd1)) begin
						cnt <= 16'd0;
						sh <= {rx_s, sh[7:1]};
						if (bit_idx == 3'd7)
							st <= 2'd3;
						else
							bit_idx <= bit_idx + 3'd1;
					end
					else
						cnt <= cnt + 16'd1;
				2'd3:
					if (cnt == (clk_div - 16'd1)) begin
						st <= 2'd0;
						data <= sh;
						valid <= rx_s;
					end
					else
						cnt <= cnt + 16'd1;
			endcase
	end
endmodule
`default_nettype none
module uart_tx (
	clk,
	rst,
	clk_div,
	start,
	data,
	busy,
	tx
);
	input wire clk;
	input wire rst;
	input wire [15:0] clk_div;
	input wire start;
	input wire [7:0] data;
	output reg busy;
	output reg tx;
	reg [3:0] bit_idx;
	reg [15:0] cnt;
	reg [9:0] shifter;
	always @(posedge clk)
		if (rst) begin
			busy <= 1'b0;
			tx <= 1'b1;
		end
		else if (!busy) begin
			tx <= 1'b1;
			if (start) begin
				shifter <= {1'b1, data, 1'b0};
				bit_idx <= 4'd0;
				cnt <= 16'd0;
				busy <= 1'b1;
			end
		end
		else begin
			tx <= shifter[0];
			if (cnt == (clk_div - 16'd1)) begin
				cnt <= 16'd0;
				shifter <= {1'b1, shifter[9:1]};
				bit_idx <= bit_idx + 4'd1;
				if (bit_idx == 4'd9)
					busy <= 1'b0;
			end
			else
				cnt <= cnt + 16'd1;
		end
endmodule
