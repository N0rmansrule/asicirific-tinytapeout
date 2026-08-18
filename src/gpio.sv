// gpio.sv — memory-mapped GPIO for buttons and sensor/control lines.
// Three word registers: OUT drives the output pins, IN reads the input pins
// (buttons), and OE selects direction on the shared bidirectional pins. Reads
// and writes complete in one cycle, so the core does not stall on GPIO.
`default_nettype none

module gpio (
    input  wire logic        clk,
    input  wire logic        rst,
    input  wire logic [3:0]  addr,      // word offset
    input  wire logic [31:0] wdata,
    input  wire logic        we,
    output logic [31:0]      rdata,
    output logic [31:0]      gpio_out,
    input  wire logic [31:0] gpio_in,
    output logic [31:0]      gpio_oe
);
    logic [31:0] out_q, oe_q;
    assign gpio_out = out_q;
    assign gpio_oe  = oe_q;

    always_comb begin
        unique case (addr)
            4'h0:    rdata = out_q;
            4'h1:    rdata = gpio_in;      // word offset 1 (byte 0x04): read the pins
            4'h2:    rdata = oe_q;         // word offset 2 (byte 0x08)
            default: rdata = 32'd0;
        endcase
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            out_q <= 32'd0;
            oe_q  <= 32'd0;
        end else if (we) begin
            unique case (addr)
                4'h0: out_q <= wdata;
                4'h2: oe_q  <= wdata;
                default: ;
            endcase
        end
    end
endmodule : gpio
