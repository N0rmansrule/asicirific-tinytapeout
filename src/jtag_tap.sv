// jtag_tap.sv — IEEE 1149.1 TAP controller with IDCODE and a DMI user register.
// This is the chip's standard programming/debug entry point. Stack:
//   jtag_tap.sv  ->  riscv_dtm.sv (Debug Transport, spec 0.13.2)  ->  riscv_dm.sv
// OpenOCD's `riscv` target drives this through any FT2232H-class adapter.
`default_nettype none

module jtag_tap #(
    parameter logic [31:0] IDCODE_VAL = 32'h1A51C1D1, // [0]=1 per spec
    parameter int unsigned IR_BITS    = 5,
    parameter int unsigned DMI_BITS   = 41            // addr+data+op per RISC-V dbg
)(
    input  wire logic tck,
    input  wire logic tms,
    input  wire logic tdi,
    input  wire logic trst_n,
    output logic      tdo,
    output logic      tdo_oe,

    // DMI shift interface toward riscv_dtm
    output logic                 dmi_capture,
    output logic                 dmi_shift,
    output logic                 dmi_update,
    output logic                 dmi_tdi,
    input  wire logic            dmi_tdo
);

    // IR encodings
    localparam logic [IR_BITS-1:0] IR_IDCODE = 5'h01;
    localparam logic [IR_BITS-1:0] IR_DTMCS  = 5'h10;
    localparam logic [IR_BITS-1:0] IR_DMI    = 5'h11;
    localparam logic [IR_BITS-1:0] IR_BYPASS = 5'h1F;

    // 1149.1 state machine
    typedef enum logic [3:0] {
        TEST_LOGIC_RESET, RUN_TEST_IDLE,
        SELECT_DR, CAPTURE_DR, SHIFT_DR, EXIT1_DR, PAUSE_DR, EXIT2_DR, UPDATE_DR,
        SELECT_IR, CAPTURE_IR, SHIFT_IR, EXIT1_IR, PAUSE_IR, EXIT2_IR, UPDATE_IR
    } tap_state_t;

    tap_state_t st;

    always_ff @(posedge tck or negedge trst_n) begin
        if (!trst_n) st <= TEST_LOGIC_RESET;
        else begin
            unique case (st)
                TEST_LOGIC_RESET: st <= tms ? TEST_LOGIC_RESET : RUN_TEST_IDLE;
                RUN_TEST_IDLE:    st <= tms ? SELECT_DR        : RUN_TEST_IDLE;
                SELECT_DR:        st <= tms ? SELECT_IR        : CAPTURE_DR;
                CAPTURE_DR:       st <= tms ? EXIT1_DR         : SHIFT_DR;
                SHIFT_DR:         st <= tms ? EXIT1_DR         : SHIFT_DR;
                EXIT1_DR:         st <= tms ? UPDATE_DR        : PAUSE_DR;
                PAUSE_DR:         st <= tms ? EXIT2_DR         : PAUSE_DR;
                EXIT2_DR:         st <= tms ? UPDATE_DR        : SHIFT_DR;
                UPDATE_DR:        st <= tms ? SELECT_DR        : RUN_TEST_IDLE;
                SELECT_IR:        st <= tms ? TEST_LOGIC_RESET : CAPTURE_IR;
                CAPTURE_IR:       st <= tms ? EXIT1_IR         : SHIFT_IR;
                SHIFT_IR:         st <= tms ? EXIT1_IR         : SHIFT_IR;
                EXIT1_IR:         st <= tms ? UPDATE_IR        : PAUSE_IR;
                PAUSE_IR:         st <= tms ? EXIT2_IR         : PAUSE_IR;
                EXIT2_IR:         st <= tms ? UPDATE_IR        : SHIFT_IR;
                UPDATE_IR:        st <= tms ? SELECT_DR        : RUN_TEST_IDLE;
                default:          st <= TEST_LOGIC_RESET;
            endcase
        end
    end

    // instruction register
    logic [IR_BITS-1:0] ir_shift, ir;

    always_ff @(posedge tck or negedge trst_n) begin
        if (!trst_n) begin
            ir_shift <= IR_IDCODE;
            ir       <= IR_IDCODE;
        end else begin
            unique case (st)
                TEST_LOGIC_RESET: ir <= IR_IDCODE;
                CAPTURE_IR:       ir_shift <= {{(IR_BITS-2){1'b0}}, 2'b01};
                SHIFT_IR:         ir_shift <= {tdi, ir_shift[IR_BITS-1:1]};
                UPDATE_IR:        ir <= ir_shift;
                default: ;
            endcase
        end
    end

    // data registers: IDCODE, BYPASS (DTMCS/DMI shift externally in riscv_dtm)
    logic [31:0] idcode_shift;
    logic        bypass_bit;

    always_ff @(posedge tck) begin
        unique case (st)
            CAPTURE_DR: begin
                idcode_shift <= IDCODE_VAL;
                bypass_bit   <= 1'b0;
            end
            SHIFT_DR: begin
                idcode_shift <= {tdi, idcode_shift[31:1]};
                bypass_bit   <= tdi;
            end
            default: ;
        endcase
    end

    // DMI strobes for the external DTM shift chain
    assign dmi_capture = (st == CAPTURE_DR) && (ir == IR_DMI || ir == IR_DTMCS);
    assign dmi_shift   = (st == SHIFT_DR)   && (ir == IR_DMI || ir == IR_DTMCS);
    assign dmi_update  = (st == UPDATE_DR)  && (ir == IR_DMI || ir == IR_DTMCS);
    assign dmi_tdi     = tdi;

    // TDO mux — changes on falling edge per 1149.1
    logic tdo_next;
    always_comb begin
        unique case (st)
            SHIFT_IR: tdo_next = ir_shift[0];
            SHIFT_DR: begin
                unique case (ir)
                    IR_IDCODE: tdo_next = idcode_shift[0];
                    IR_DMI, IR_DTMCS: tdo_next = dmi_tdo;
                    default:   tdo_next = bypass_bit;
                endcase
            end
            default: tdo_next = 1'b0;
        endcase
    end

    always_ff @(negedge tck) begin
        tdo    <= tdo_next;
        tdo_oe <= (st == SHIFT_IR) || (st == SHIFT_DR);
    end

endmodule : jtag_tap
