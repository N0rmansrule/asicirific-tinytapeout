// forwarding_unit.sv — X-stage operand bypass select.
// 00 = regfile value from D, 01 = forward from M (ALU of older inst),
// 10 = forward from W (final writeback data).
`default_nettype none

module forwarding_unit (
    input  wire logic [4:0] rs1_x,
    input  wire logic [4:0] rs2_x,
    input  wire logic [4:0] rd_m,
    input  wire logic       rf_we_m,
    input  wire logic       is_load_m,      // load result not ready in M
    input  wire logic [4:0] rd_w,
    input  wire logic       rf_we_w,
    output logic [1:0]      fwd_a,
    output logic [1:0]      fwd_b
);
    always_comb begin
        fwd_a = 2'b00;
        fwd_b = 2'b00;
        if (rf_we_m && !is_load_m && (rd_m != 5'd0) && (rd_m == rs1_x)) fwd_a = 2'b01;
        else if (rf_we_w && (rd_w != 5'd0) && (rd_w == rs1_x))          fwd_a = 2'b10;
        if (rf_we_m && !is_load_m && (rd_m != 5'd0) && (rd_m == rs2_x)) fwd_b = 2'b01;
        else if (rf_we_w && (rd_w != 5'd0) && (rd_w == rs2_x))          fwd_b = 2'b10;
    end
endmodule : forwarding_unit
