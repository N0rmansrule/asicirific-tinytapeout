// ras.sv — Return Address Stack for JAL(R) call/return prediction.
`default_nettype none

module ras #(
    parameter int unsigned DEPTH_LOG2 = 3    // 8 entries
)(
    input  wire logic        clk,
    input  wire logic        rst,
    input  wire logic        push,           // call: JAL/JALR with rd=x1/x5
    input  wire logic [31:0] push_addr,      // pc + 4
    input  wire logic        pop,            // return: JALR with rs1=x1/x5
    output logic [31:0]      top_addr,
    output logic             top_valid
);
    localparam int unsigned DEPTH = 1 << DEPTH_LOG2;

    logic [31:0]           stack [DEPTH-1:0];
    logic [DEPTH_LOG2-1:0] sp;
    logic [DEPTH_LOG2:0]   count;

    assign top_valid = (count != '0);
    assign top_addr  = stack[sp - 1'b1];

    always_ff @(posedge clk) begin
        if (rst) begin
            sp <= '0; count <= '0;
        end else begin
            unique case ({push, pop})
                2'b10: begin
                    stack[sp] <= push_addr;
                    sp <= sp + 1'b1;
                    if (count != {1'b1, {DEPTH_LOG2{1'b0}}}) count <= count + 1'b1;
                end
                2'b01: if (count != '0) begin
                    sp <= sp - 1'b1;
                    count <= count - 1'b1;
                end
                2'b11: stack[sp - 1'b1] <= push_addr; // call+return same cycle: swap top
                default: ;
            endcase
        end
    end
endmodule : ras
