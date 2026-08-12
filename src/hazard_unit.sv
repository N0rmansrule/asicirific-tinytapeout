// hazard_unit.sv — stall/flush generation.
// Load-use: consumer in D while load in X -> stall front end one cycle.
// Div busy: stall front end until div_unit finishes.
`default_nettype none

module hazard_unit (
    input  wire logic [4:0] rs1_d,
    input  wire logic [4:0] rs2_d,
    input  wire logic       uses_rs1_d,
    input  wire logic       uses_rs2_d,
    input  wire logic [4:0] rd_x,
    input  wire logic       mem_read_x,
    input  wire logic       div_busy,
    output logic            stall,
    output logic            bubble_x
);
    logic load_use;
    always_comb begin
        load_use = mem_read_x && (rd_x != 5'd0) &&
                   ((uses_rs1_d && (rd_x == rs1_d)) ||
                    (uses_rs2_d && (rd_x == rs2_d)));
        stall    = load_use || div_busy;
        bubble_x = load_use;   // insert NOP into X while D holds
    end
endmodule : hazard_unit
