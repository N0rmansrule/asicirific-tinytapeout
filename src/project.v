`default_nettype none
`default_nettype none
module branch_comp (
	funct3,
	zero,
	lt_signed,
	lt_unsigned,
	taken
);
	reg _sv2v_0;
	input wire [2:0] funct3;
	input wire zero;
	input wire lt_signed;
	input wire lt_unsigned;
	output reg taken;
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (funct3)
			3'b000: taken = zero;
			3'b001: taken = ~zero;
			3'b100: taken = lt_signed;
			3'b101: taken = ~lt_signed;
			3'b110: taken = lt_unsigned;
			3'b111: taken = ~lt_unsigned;
			default: taken = 1'b0;
		endcase
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
	output wire [31:0] gpio_out;
	input wire [31:0] gpio_in;
	output wire [31:0] gpio_oe;
	reg [31:0] out_q;
	reg [31:0] oe_q;
	assign gpio_out = out_q;
	assign gpio_oe = oe_q;
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (addr)
			4'h0: rdata = out_q;
			4'h1: rdata = gpio_in;
			4'h2: rdata = oe_q;
			default: rdata = 32'd0;
		endcase
	end
	always @(posedge clk)
		if (rst) begin
			out_q <= 32'd0;
			oe_q <= 32'd0;
		end
		else if (we)
			(* full_case, parallel_case *)
			case (addr)
				4'h0: out_q <= wdata;
				4'h2: oe_q <= wdata;
				default:
					;
			endcase
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
module mem_bus (
	clk,
	rst,
	c_addr,
	c_wdata,
	c_be,
	c_we,
	c_re,
	c_rdata,
	c_ready,
	m_addr,
	m_wdata,
	m_be,
	m_we,
	m_re,
	m_rdata,
	m_ready,
	g_addr,
	g_wdata,
	g_we,
	g_rdata,
	sel_gpio_o
);
	input wire clk;
	input wire rst;
	input wire [31:0] c_addr;
	input wire [31:0] c_wdata;
	input wire [3:0] c_be;
	input wire c_we;
	input wire c_re;
	output wire [31:0] c_rdata;
	output wire c_ready;
	output wire [31:0] m_addr;
	output wire [31:0] m_wdata;
	output wire [3:0] m_be;
	output wire m_we;
	output wire m_re;
	input wire [31:0] m_rdata;
	input wire m_ready;
	output wire [3:0] g_addr;
	output wire [31:0] g_wdata;
	output wire g_we;
	input wire [31:0] g_rdata;
	output wire sel_gpio_o;
	wire is_gpio = c_addr[31:24] == 8'h02;
	assign sel_gpio_o = is_gpio;
	assign m_addr = c_addr;
	assign m_wdata = c_wdata;
	assign m_be = c_be;
	assign m_we = c_we && !is_gpio;
	assign m_re = c_re && !is_gpio;
	assign g_addr = c_addr[5:2];
	assign g_wdata = c_wdata;
	assign g_we = c_we && is_gpio;
	reg gpio_ready;
	always @(posedge clk)
		if (rst)
			gpio_ready <= 1'b0;
		else
			gpio_ready <= ((c_re || c_we) && is_gpio) && !gpio_ready;
	assign c_rdata = (is_gpio ? g_rdata : m_rdata);
	assign c_ready = (is_gpio ? gpio_ready : m_ready);
endmodule
`default_nettype none
module serial_alu (
	clk,
	rst,
	init,
	en,
	op,
	a,
	b,
	y,
	last_cout
);
	reg _sv2v_0;
	input wire clk;
	input wire rst;
	input wire init;
	input wire en;
	input wire [3:0] op;
	input wire a;
	input wire b;
	output reg y;
	output wire last_cout;
	wire sub = ((op == 4'd1) || (op == 4'd5)) || (op == 4'd6);
	wire bb = (sub ? ~b : b);
	reg carry;
	wire cin = (init ? (sub ? 1'b1 : 1'b0) : carry);
	wire sum = (a ^ bb) ^ cin;
	wire cout = ((a & bb) | (a & cin)) | (bb & cin);
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (op)
			4'd2: y = a & b;
			4'd3: y = a | b;
			4'd4: y = a ^ b;
			default: y = sum;
		endcase
	end
	assign last_cout = cout;
	always @(posedge clk)
		if (rst)
			carry <= 1'b0;
		else if (en)
			carry <= cout;
	initial _sv2v_0 = 0;
endmodule
`default_nettype none
module serial_core (
	clk,
	rst,
	mem_addr,
	mem_wdata,
	mem_be,
	mem_we,
	mem_re,
	mem_rdata,
	mem_ready
);
	reg _sv2v_0;
	parameter [31:0] RESET_PC = 32'h00000000;
	input wire clk;
	input wire rst;
	output reg [31:0] mem_addr;
	output reg [31:0] mem_wdata;
	output reg [3:0] mem_be;
	output reg mem_we;
	output reg mem_re;
	input wire [31:0] mem_rdata;
	input wire mem_ready;
	reg [3:0] st;
	reg [31:0] pc;
	reg [31:0] ir;
	reg [31:0] imm_sr;
	reg [31:0] tgt_sr;
	reg [31:0] addr_sr;
	reg [31:0] data_sr;
	reg [5:0] bitcnt;
	reg [4:0] shamt;
	reg zero_acc;
	reg cmp_taken;
	wire [6:0] opc = ir[6:0];
	wire [4:0] rd = ir[11:7];
	wire [2:0] f3 = ir[14:12];
	wire [4:0] rs1 = ir[19:15];
	wire [4:0] rs2 = ir[24:20];
	wire [6:0] f7 = ir[31:25];
	localparam [6:0] asicirific_pkg_OPC_LUI = 7'b0110111;
	wire is_lui = opc == asicirific_pkg_OPC_LUI;
	localparam [6:0] asicirific_pkg_OPC_AUIPC = 7'b0010111;
	wire is_auipc = opc == asicirific_pkg_OPC_AUIPC;
	localparam [6:0] asicirific_pkg_OPC_OPIMM = 7'b0010011;
	wire is_opimm = opc == asicirific_pkg_OPC_OPIMM;
	localparam [6:0] asicirific_pkg_OPC_OP = 7'b0110011;
	wire is_op = opc == asicirific_pkg_OPC_OP;
	localparam [6:0] asicirific_pkg_OPC_BRANCH = 7'b1100011;
	wire is_br = opc == asicirific_pkg_OPC_BRANCH;
	localparam [6:0] asicirific_pkg_OPC_JAL = 7'b1101111;
	wire is_jal = opc == asicirific_pkg_OPC_JAL;
	localparam [6:0] asicirific_pkg_OPC_JALR = 7'b1100111;
	wire is_jalr = opc == asicirific_pkg_OPC_JALR;
	localparam [6:0] asicirific_pkg_OPC_LOAD = 7'b0000011;
	wire is_load = opc == asicirific_pkg_OPC_LOAD;
	localparam [6:0] asicirific_pkg_OPC_STORE = 7'b0100011;
	wire is_store = opc == asicirific_pkg_OPC_STORE;
	wire is_shift = (is_op || is_opimm) && ((f3 == 3'b001) || (f3 == 3'b101));
	wire shift_right = f3 == 3'b101;
	wire shift_arith = f7[5];
	wire alu_writes = (((is_lui || is_auipc) || is_opimm) || is_op) && !is_shift;
	reg [2:0] f_sel;
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (mem_rdata[6:0])
			asicirific_pkg_OPC_STORE: f_sel = 3'd1;
			asicirific_pkg_OPC_BRANCH: f_sel = 3'd2;
			asicirific_pkg_OPC_LUI, asicirific_pkg_OPC_AUIPC: f_sel = 3'd3;
			asicirific_pkg_OPC_JAL: f_sel = 3'd4;
			default: f_sel = 3'd0;
		endcase
	end
	wire [31:0] imm_full;
	imm_gen u_imm(
		.inst(mem_rdata),
		.sel(f_sel),
		.imm(imm_full)
	);
	reg [3:0] alu_op;
	always @(*) begin
		if (_sv2v_0)
			;
		alu_op = 4'd0;
		if (is_op || is_opimm)
			(* full_case, parallel_case *)
			case (f3)
				3'b000: alu_op = (is_op && f7[5] ? 4'd1 : 4'd0);
				3'b111: alu_op = 4'd2;
				3'b110: alu_op = 4'd3;
				3'b100: alu_op = 4'd4;
				3'b010: alu_op = 4'd5;
				3'b011: alu_op = 4'd6;
				default: alu_op = 4'd0;
			endcase
	end
	wire rs1_bit;
	wire rs2_bit;
	reg rf_we;
	reg rf_wbit;
	reg rf_en;
	reg rf_shl;
	reg rf_shr;
	reg rf_shin;
	wire rd_msb;
	serial_rf u_rf(
		.clk(clk),
		.rst(rst),
		.en(rf_en),
		.rs1(rs1[3:0]),
		.rs2(rs2[3:0]),
		.rd(rd[3:0]),
		.we(rf_we),
		.wbit(rf_wbit),
		.shl(rf_shl),
		.shr(rf_shr),
		.shin(rf_shin),
		.rs1_bit(rs1_bit),
		.rs2_bit(rs2_bit),
		.rd_msb(rd_msb)
	);
	wire use_pc_a = (st == 4'd3) || is_auipc;
	wire use_imm_b = ((((st == 4'd1) && ((is_opimm || is_lui) || is_auipc)) || (st == 4'd3)) || (st == 4'd5)) || (st == 4'd6);
	wire a_bit = (use_pc_a ? pc[bitcnt] : (is_lui ? 1'b0 : rs1_bit));
	wire b_bit = (use_imm_b ? imm_sr[0] : rs2_bit);
	reg [3:0] alu_op_eff;
	always @(*) begin
		if (_sv2v_0)
			;
		if (st == 4'd2)
			alu_op_eff = 4'd1;
		else if ((((st == 4'd3) || (st == 4'd5)) || (st == 4'd6)) || (st == 4'd10))
			alu_op_eff = 4'd0;
		else
			alu_op_eff = alu_op;
	end
	wire alu_y;
	wire alu_cout;
	reg alu_en;
	reg alu_init;
	serial_alu u_alu(
		.clk(clk),
		.rst(rst),
		.init(alu_init),
		.en(alu_en),
		.op(alu_op_eff),
		.a(a_bit),
		.b(b_bit),
		.y(alu_y),
		.last_cout(alu_cout)
	);
	wire [31:0] pc4 = pc + 32'd4;
	wire cmp_lt_u = ~alu_cout;
	wire cmp_lt_s = (rs1_bit ^ rs2_bit ? rs1_bit : alu_y);
	wire cmp_zero = zero_acc && (alu_y == 1'b0);
	wire br_taken;
	branch_comp u_bc(
		.funct3(f3),
		.zero(cmp_zero),
		.lt_signed(cmp_lt_s),
		.lt_unsigned(cmp_lt_u),
		.taken(br_taken)
	);
	wire [31:0] ld_result;
	load_unit u_ld(
		.rdata(mem_rdata),
		.addr_lo(addr_sr[1:0]),
		.funct3(f3),
		.out(ld_result)
	);
	wire [31:0] st_wdata;
	wire [3:0] st_be;
	store_unit u_st(
		.wdata_in(data_sr),
		.addr_lo(addr_sr[1:0]),
		.funct3(f3),
		.wdata_out(st_wdata),
		.be(st_be)
	);
	always @(*) begin
		if (_sv2v_0)
			;
		mem_re = (st == 4'd0) || (st == 4'd7);
		mem_we = st == 4'd9;
		mem_addr = (st == 4'd0 ? pc : {addr_sr[31:2], 2'b00});
		mem_wdata = st_wdata;
		mem_be = st_be;
	end
	wire alu_pass = (((((((st == 4'd1) || (st == 4'd2)) || (st == 4'd3)) || (st == 4'd4)) || (st == 4'd5)) || (st == 4'd6)) || (st == 4'd8)) || (st == 4'd10);
	always @(*) begin
		if (_sv2v_0)
			;
		alu_en = alu_pass;
		alu_init = alu_pass && (bitcnt == 6'd0);
		rf_en = alu_pass;
		rf_we = ((((st == 4'd1) && alu_writes) || ((st == 4'd4) && (is_jal || is_jalr))) || (st == 4'd8)) || (st == 4'd10);
		if (st == 4'd4)
			rf_wbit = pc4[bitcnt];
		else if (st == 4'd8)
			rf_wbit = data_sr[0];
		else if (st == 4'd10)
			rf_wbit = rs1_bit;
		else
			rf_wbit = alu_y;
		rf_shl = (st == 4'd11) && !shift_right;
		rf_shr = (st == 4'd11) && shift_right;
		rf_shin = (shift_arith ? rd_msb : 1'b0);
	end
	always @(posedge clk)
		if (rst) begin
			st <= 4'd0;
			pc <= RESET_PC;
		end
		else
			(* full_case, parallel_case *)
			case (st)
				4'd0:
					if (mem_ready) begin
						ir <= mem_rdata;
						imm_sr <= imm_full;
						bitcnt <= 6'd0;
						zero_acc <= 1'b1;
						shamt <= mem_rdata[24:20];
						(* full_case, parallel_case *)
						case (mem_rdata[6:0])
							asicirific_pkg_OPC_BRANCH: st <= 4'd2;
							asicirific_pkg_OPC_JAL: st <= 4'd4;
							asicirific_pkg_OPC_JALR: st <= 4'd4;
							asicirific_pkg_OPC_LOAD: st <= 4'd6;
							asicirific_pkg_OPC_STORE: st <= 4'd6;
							default:
								if (((mem_rdata[6:0] == asicirific_pkg_OPC_OP) || (mem_rdata[6:0] == asicirific_pkg_OPC_OPIMM)) && ((mem_rdata[14:12] == 3'b001) || (mem_rdata[14:12] == 3'b101)))
									st <= 4'd10;
								else
									st <= 4'd1;
						endcase
					end
				4'd1: begin
					if (use_imm_b)
						imm_sr <= {1'b0, imm_sr[31:1]};
					bitcnt <= bitcnt + 6'd1;
					if (bitcnt == 6'd31)
						st <= 4'd12;
				end
				4'd2: begin
					if (alu_y != 1'b0)
						zero_acc <= 1'b0;
					if (bitcnt == 6'd31) begin
						cmp_taken <= br_taken;
						bitcnt <= 6'd0;
						st <= 4'd3;
					end
					else
						bitcnt <= bitcnt + 6'd1;
				end
				4'd3: begin
					tgt_sr <= {alu_y, tgt_sr[31:1]};
					imm_sr <= {1'b0, imm_sr[31:1]};
					if (bitcnt == 6'd31) begin
						if (is_jal || cmp_taken)
							pc <= {alu_y, tgt_sr[31:1]};
						else
							pc <= pc4;
						st <= 4'd0;
					end
					else
						bitcnt <= bitcnt + 6'd1;
				end
				4'd4: begin
					bitcnt <= bitcnt + 6'd1;
					if (bitcnt == 6'd31) begin
						bitcnt <= 6'd0;
						st <= (is_jalr ? 4'd5 : 4'd3);
					end
				end
				4'd5: begin
					tgt_sr <= {alu_y, tgt_sr[31:1]};
					imm_sr <= {1'b0, imm_sr[31:1]};
					if (bitcnt == 6'd31) begin
						pc <= {alu_y, tgt_sr[31:1]} & ~32'd1;
						st <= 4'd0;
					end
					else
						bitcnt <= bitcnt + 6'd1;
				end
				4'd6: begin
					addr_sr <= {alu_y, addr_sr[31:1]};
					data_sr <= {rs2_bit, data_sr[31:1]};
					imm_sr <= {1'b0, imm_sr[31:1]};
					if (bitcnt == 6'd31)
						st <= (is_load ? 4'd7 : 4'd9);
					else
						bitcnt <= bitcnt + 6'd1;
				end
				4'd7:
					if (mem_ready) begin
						data_sr <= ld_result;
						bitcnt <= 6'd0;
						st <= 4'd8;
					end
				4'd8: begin
					data_sr <= {1'b0, data_sr[31:1]};
					bitcnt <= bitcnt + 6'd1;
					if (bitcnt == 6'd31)
						st <= 4'd12;
				end
				4'd9:
					if (mem_ready)
						st <= 4'd12;
				4'd10: begin
					if ((bitcnt < 6'd5) && is_op)
						shamt[bitcnt[2:0]] <= rs2_bit;
					bitcnt <= bitcnt + 6'd1;
					if (bitcnt == 6'd31)
						st <= (shamt == 5'd0 ? 4'd12 : 4'd11);
				end
				4'd11: begin
					shamt <= shamt - 5'd1;
					if (shamt == 5'd1)
						st <= 4'd12;
				end
				4'd12: begin
					pc <= pc4;
					st <= 4'd0;
				end
				default: st <= 4'd0;
			endcase
	initial _sv2v_0 = 0;
endmodule
`default_nettype none
module serial_rf (
	clk,
	rst,
	en,
	rs1,
	rs2,
	rd,
	we,
	wbit,
	shl,
	shr,
	shin,
	rs1_bit,
	rs2_bit,
	rd_msb
);
	input wire clk;
	input wire rst;
	input wire en;
	input wire [3:0] rs1;
	input wire [3:0] rs2;
	input wire [3:0] rd;
	input wire we;
	input wire wbit;
	input wire shl;
	input wire shr;
	input wire shin;
	output wire rs1_bit;
	output wire rs2_bit;
	output wire rd_msb;
	reg [31:0] sr [15:0];
	assign rs1_bit = (rs1 == 4'd0 ? 1'b0 : sr[rs1][0]);
	assign rs2_bit = (rs2 == 4'd0 ? 1'b0 : sr[rs2][0]);
	assign rd_msb = sr[rd][31];
	integer i;
	always @(posedge clk)
		if (rst)
			for (i = 0; i < 16; i = i + 1)
				sr[i] <= 32'd0;
		else if (shl || shr) begin
			if (rd != 4'd0) begin
				if (shr)
					sr[rd] <= {shin, sr[rd][31:1]};
				else
					sr[rd] <= {sr[rd][30:0], 1'b0};
			end
		end
		else if (en) begin
			for (i = 0; i < 16; i = i + 1)
				if ((we && (rd != 4'd0)) && (i == rd))
					sr[i] <= {wbit, sr[i][31:1]};
				else
					sr[i] <= {sr[i][0], sr[i][31:1]};
		end
endmodule
`default_nettype none
module spi_mem (
	clk,
	rst,
	addr,
	re,
	we,
	wdata,
	be,
	rdata,
	ready,
	sck,
	sd0,
	sd1,
	cs_flash_n,
	cs_ram_n
);
	reg _sv2v_0;
	input wire clk;
	input wire rst;
	input wire [31:0] addr;
	input wire re;
	input wire we;
	input wire [31:0] wdata;
	input wire [3:0] be;
	output wire [31:0] rdata;
	output wire ready;
	output reg sck;
	output wire sd0;
	input wire sd1;
	output wire cs_flash_n;
	output wire cs_ram_n;
	wire sel_ram = addr[24];
	wire [23:0] byte_addr = {addr[23:2], 2'b00};
	reg [2:0] st;
	reg [1:0] ph;
	reg [31:0] sh_out;
	reg [31:0] sh_in;
	reg [5:0] bits;
	reg rmw;
	reg [31:0] wsave;
	reg [3:0] besave;
	reg for_ram;
	assign sd0 = sh_out[31];
	assign cs_flash_n = ((st == 3'd0) || (st == 3'd3)) || for_ram;
	assign cs_ram_n = ((st == 3'd0) || (st == 3'd3)) || !for_ram;
	assign rdata = sh_in;
	assign ready = st == 3'd4;
	reg [31:0] merged;
	always @(*) begin
		if (_sv2v_0)
			;
		merged = sh_in;
		if (besave[0])
			merged[7:0] = wsave[7:0];
		if (besave[1])
			merged[15:8] = wsave[15:8];
		if (besave[2])
			merged[23:16] = wsave[23:16];
		if (besave[3])
			merged[31:24] = wsave[31:24];
	end
	always @(posedge clk)
		if (rst) begin
			st <= 3'd0;
			sck <= 1'b0;
			sh_out <= 32'd0;
			sh_in <= 32'd0;
			for_ram <= 1'b0;
			rmw <= 1'b0;
		end
		else
			(* full_case, parallel_case *)
			case (st)
				3'd0: begin
					sck <= 1'b0;
					if (re) begin
						for_ram <= sel_ram;
						rmw <= 1'b0;
						sh_out <= {8'h03, byte_addr};
						bits <= 6'd32;
						ph <= 2'd0;
						st <= 3'd1;
					end
					else if (we) begin
						for_ram <= 1'b1;
						wsave <= wdata;
						besave <= be;
						if (be == 4'b1111) begin
							rmw <= 1'b0;
							sh_out <= {8'h02, byte_addr};
							bits <= 6'd32;
							ph <= 2'd0;
						end
						else begin
							rmw <= 1'b1;
							sh_out <= {8'h03, byte_addr};
							bits <= 6'd32;
							ph <= 2'd0;
						end
						st <= 3'd1;
					end
				end
				3'd1:
					if (sck == 1'b0) begin
						sck <= 1'b1;
						sh_in <= {sh_in[30:0], sd1};
					end
					else begin
						sck <= 1'b0;
						sh_out <= {sh_out[30:0], 1'b0};
						bits <= bits - 6'd1;
						if (bits == 6'd1)
							st <= 3'd2;
					end
				3'd2:
					(* full_case, parallel_case *)
					case (ph)
						2'd0:
							if (we && !rmw) begin
								sh_out <= wsave;
								bits <= 6'd32;
								ph <= 2'd2;
								st <= 3'd1;
							end
							else begin
								bits <= 6'd32;
								ph <= 2'd1;
								st <= 3'd1;
							end
						2'd1:
							if (rmw) begin
								wsave <= merged;
								st <= 3'd3;
							end
							else
								st <= 3'd4;
						2'd2: st <= 3'd4;
						default: st <= 3'd4;
					endcase
				3'd3: begin
					sh_out <= {8'h02, byte_addr};
					bits <= 6'd32;
					ph <= 2'd0;
					rmw <= 1'b0;
					st <= 3'd1;
				end
				3'd4: st <= 3'd0;
				default: st <= 3'd0;
			endcase
	initial _sv2v_0 = 0;
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
	wire [31:0] c_addr;
	wire [31:0] c_wdata;
	wire [31:0] c_rdata;
	wire [3:0] c_be;
	wire c_we;
	wire c_re;
	wire c_ready;
	serial_core #(.RESET_PC(32'h00000000)) u_core(
		.clk(clk),
		.rst(rst),
		.mem_addr(c_addr),
		.mem_wdata(c_wdata),
		.mem_be(c_be),
		.mem_we(c_we),
		.mem_re(c_re),
		.mem_rdata(c_rdata),
		.mem_ready(c_ready)
	);
	wire [31:0] m_addr;
	wire [31:0] m_wdata;
	wire [31:0] m_rdata;
	wire [3:0] m_be;
	wire m_we;
	wire m_re;
	wire m_ready;
	wire [3:0] g_addr;
	wire [31:0] g_wdata;
	wire [31:0] g_rdata;
	wire g_we;
	wire sel_gpio;
	mem_bus u_bus(
		.clk(clk),
		.rst(rst),
		.c_addr(c_addr),
		.c_wdata(c_wdata),
		.c_be(c_be),
		.c_we(c_we),
		.c_re(c_re),
		.c_rdata(c_rdata),
		.c_ready(c_ready),
		.m_addr(m_addr),
		.m_wdata(m_wdata),
		.m_be(m_be),
		.m_we(m_we),
		.m_re(m_re),
		.m_rdata(m_rdata),
		.m_ready(m_ready),
		.g_addr(g_addr),
		.g_wdata(g_wdata),
		.g_we(g_we),
		.g_rdata(g_rdata),
		.sel_gpio_o(sel_gpio)
	);
	wire spi_sck;
	wire spi_sd0;
	wire spi_sd1;
	wire cs_flash_n;
	wire cs_ram_n;
	spi_mem u_spi(
		.clk(clk),
		.rst(rst),
		.addr(m_addr),
		.re(m_re),
		.we(m_we),
		.wdata(m_wdata),
		.be(m_be),
		.rdata(m_rdata),
		.ready(m_ready),
		.sck(spi_sck),
		.sd0(spi_sd0),
		.sd1(spi_sd1),
		.cs_flash_n(cs_flash_n),
		.cs_ram_n(cs_ram_n)
	);
	wire [31:0] gpio_out;
	wire [31:0] gpio_in;
	wire [31:0] gpio_oe;
	assign gpio_in = {24'd0, ui_in};
	gpio u_gpio(
		.clk(clk),
		.rst(rst),
		.addr(g_addr),
		.wdata(g_wdata),
		.we(g_we),
		.rdata(g_rdata),
		.gpio_out(gpio_out),
		.gpio_in(gpio_in),
		.gpio_oe(gpio_oe)
	);
	assign uo_out = gpio_out[7:0];
	assign uio_out[0] = spi_sd0;
	assign uio_out[1] = 1'b0;
	assign uio_out[2] = 1'b0;
	assign uio_out[3] = 1'b0;
	assign uio_out[4] = spi_sck;
	assign uio_out[5] = cs_flash_n;
	assign uio_out[6] = cs_ram_n;
	assign uio_out[7] = gpio_out[8];
	assign uio_oe[0] = 1'b1;
	assign uio_oe[1] = 1'b0;
	assign uio_oe[2] = 1'b1;
	assign uio_oe[3] = 1'b1;
	assign uio_oe[4] = 1'b1;
	assign uio_oe[5] = 1'b1;
	assign uio_oe[6] = 1'b1;
	assign uio_oe[7] = 1'b1;
	assign spi_sd1 = uio_in[1];
	wire _unused = &{ena, gpio_oe, gpio_in[31:8], uio_in[0], uio_in[7:2], 1'b0};
endmodule
