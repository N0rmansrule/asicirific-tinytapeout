// uart.sv — MMIO wrapper.
// 0x0 DATA   : write = tx byte, read = rx byte (pops flag)
// 0x4 STATUS : [0] tx_busy, [1] rx_avail
// 0x8 CLKDIV : clocks per bit (reset = 217 -> 115200 @ 25 MHz)
`default_nettype none
module uart (
    input  wire logic        clk,
    input  wire logic        rst,
    input  wire logic [3:0]  addr,
    input  wire logic [31:0] wdata,
    input  wire logic        we,
    input  wire logic        re,
    output logic [31:0]      rdata,
    output logic             tx,
    input  wire logic        rx
);
    logic [15:0] clk_div;
    logic tx_busy, rx_valid, rx_avail;
    logic [7:0] rx_data, rx_hold;

    uart_tx u_tx (.clk(clk), .rst(rst), .clk_div(clk_div),
                  .start(we && addr == 4'h0), .data(wdata[7:0]),
                  .busy(tx_busy), .tx(tx));
    uart_rx u_rx (.clk(clk), .rst(rst), .clk_div(clk_div),
                  .rx(rx), .valid(rx_valid), .data(rx_data));

    always_ff @(posedge clk) begin
        if (rst) begin
            clk_div  <= 16'd217;
            rx_avail <= 1'b0;
        end else begin
            if (rx_valid) begin rx_hold <= rx_data; rx_avail <= 1'b1; end
            if (re && addr == 4'h0) rx_avail <= 1'b0;
            if (we && addr == 4'h8) clk_div <= wdata[15:0];
        end
    end

    always_comb begin
        unique case (addr)
            4'h0:    rdata = {24'd0, rx_hold};
            4'h4:    rdata = {30'd0, rx_avail, tx_busy};
            4'h8:    rdata = {16'd0, clk_div};
            default: rdata = 32'd0;
        endcase
    end
endmodule : uart
