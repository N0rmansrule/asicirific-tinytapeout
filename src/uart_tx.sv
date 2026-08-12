// uart_tx.sv — 8N1 transmitter, programmable clock divider.
`default_nettype none
module uart_tx (
    input  wire logic        clk,
    input  wire logic        rst,
    input  wire logic [15:0] clk_div,     // clocks per bit
    input  wire logic        start,
    input  wire logic [7:0]  data,
    output logic             busy,
    output logic             tx
);
    logic [3:0]  bit_idx;
    logic [15:0] cnt;
    logic [9:0]  shifter;   // stop, data[7:0], start

    always_ff @(posedge clk) begin
        if (rst) begin
            busy <= 1'b0; tx <= 1'b1;
        end else if (!busy) begin
            tx <= 1'b1;
            if (start) begin
                shifter <= {1'b1, data, 1'b0};
                bit_idx <= 4'd0;
                cnt     <= 16'd0;
                busy    <= 1'b1;
            end
        end else begin
            tx <= shifter[0];
            if (cnt == clk_div - 16'd1) begin
                cnt     <= 16'd0;
                shifter <= {1'b1, shifter[9:1]};
                bit_idx <= bit_idx + 4'd1;
                if (bit_idx == 4'd9) busy <= 1'b0;
            end else cnt <= cnt + 16'd1;
        end
    end
endmodule : uart_tx
