// gpio.sv — 8-bit GPIO. 0x0 OUT, 0x4 IN (synced), 0x8 OE.
`default_nettype none
module gpio (
    input  wire logic        clk,
    input  wire logic        rst,
    input  wire logic [3:0]  addr,
    input  wire logic [31:0] wdata,
    input  wire logic        we,
    output logic [31:0]      rdata,
    output logic [7:0]       gpio_out,
    input  wire logic [7:0]  gpio_in,
    output logic [7:0]       gpio_oe
);
    logic [7:0] in_m, in_s;
    always_ff @(posedge clk) begin
        in_m <= gpio_in; in_s <= in_m;
        if (rst) begin
            gpio_out <= 8'd0; gpio_oe <= 8'd0;
        end else if (we) begin
            unique case (addr)
                4'h0: gpio_out <= wdata[7:0];
                4'h8: gpio_oe  <= wdata[7:0];
                default: ;
            endcase
        end
    end
    always_comb begin
        unique case (addr)
            4'h0:    rdata = {24'd0, gpio_out};
            4'h4:    rdata = {24'd0, in_s};
            4'h8:    rdata = {24'd0, gpio_oe};
            default: rdata = 32'd0;
        endcase
    end
endmodule : gpio
