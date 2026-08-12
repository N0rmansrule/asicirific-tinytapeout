// div_unit.sv — iterative restoring divider, 32 cycles + setup.
// Handles RISC-V div-by-zero and signed-overflow semantics.
`default_nettype none

module div_unit (
    input  wire logic        clk,
    input  wire logic        rst,
    input  wire logic        start,
    input  wire logic [31:0] a,        // dividend
    input  wire logic [31:0] b,        // divisor
    input  wire logic [2:0]  funct3,   // 100 DIV, 101 DIVU, 110 REM, 111 REMU
    output logic             busy,
    output logic             done,     // 1-cycle pulse, result valid
    output logic [31:0]      y
);
    logic        is_signed, want_rem;
    logic        neg_q, neg_r;
    logic [31:0] ua, ub;
    logic [31:0] quo;
    logic [32:0] rem;
    logic [5:0]  cnt;
    logic        running;

    assign busy = running;

    always_ff @(posedge clk) begin
        done <= 1'b0;
        if (rst) begin
            running <= 1'b0;
        end else if (start && !running) begin
            is_signed <= ~funct3[0];
            want_rem  <=  funct3[1];
            // special cases resolved immediately
            if (b == 32'd0) begin
                y    <= funct3[1] ? a : 32'hFFFF_FFFF;  // rem=a, div=-1
                done <= 1'b1;
            end else if (~funct3[0] && a == 32'h8000_0000 && b == 32'hFFFF_FFFF) begin
                y    <= funct3[1] ? 32'd0 : 32'h8000_0000; // signed overflow
                done <= 1'b1;
            end else begin
                neg_q   <= (~funct3[0]) && (a[31] ^ b[31]);
                neg_r   <= (~funct3[0]) && a[31];
                ua      <= (~funct3[0] && a[31]) ? (~a + 32'd1) : a;
                ub      <= (~funct3[0] && b[31]) ? (~b + 32'd1) : b;
                quo     <= 32'd0;
                rem     <= 33'd0;
                cnt     <= 6'd32;
                running <= 1'b1;
            end
        end else if (running) begin
            logic [32:0] r_shift;
            logic [32:0] r_sub;
            r_shift = {rem[31:0], ua[31]};
            r_sub   = r_shift - {1'b0, ub};
            ua      <= {ua[30:0], 1'b0};
            if (!r_sub[32]) begin
                rem <= r_sub;
                quo <= {quo[30:0], 1'b1};
            end else begin
                rem <= r_shift;
                quo <= {quo[30:0], 1'b0};
            end
            cnt <= cnt - 6'd1;
            if (cnt == 6'd1) begin
                logic [31:0] rem_f, quo_f;
                if (!r_sub[32]) begin rem_f = r_sub[31:0]; quo_f = {quo[30:0], 1'b1}; end
                else            begin rem_f = r_shift[31:0]; quo_f = {quo[30:0], 1'b0}; end
                running <= 1'b0;
                done    <= 1'b1;
                if (want_rem) y <= neg_r ? (~rem_f + 32'd1) : rem_f;
                else          y <= neg_q ? (~quo_f + 32'd1) : quo_f;
            end
        end
    end
endmodule : div_unit
