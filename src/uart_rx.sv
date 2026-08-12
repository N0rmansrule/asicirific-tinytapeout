// uart_rx.sv — 8N1 receiver with mid-bit sampling and 2FF input sync.
`default_nettype none
module uart_rx (
    input  wire logic        clk,
    input  wire logic        rst,
    input  wire logic [15:0] clk_div,
    input  wire logic        rx,
    output logic             valid,       // 1-cycle pulse
    output logic [7:0]       data
);
    logic rx_m, rx_s;
    always_ff @(posedge clk) begin
        rx_m <= rx; rx_s <= rx_m;
    end

    typedef enum logic [1:0] {IDLE, START, DATA, STOP} st_t;
    st_t st;
    logic [15:0] cnt;
    logic [2:0]  bit_idx;
    logic [7:0]  sh;

    always_ff @(posedge clk) begin
        valid <= 1'b0;
        if (rst) begin
            st <= IDLE;
        end else begin
            unique case (st)
                IDLE: if (!rx_s) begin st <= START; cnt <= 16'd0; end
                START: begin
                    if (cnt == (clk_div >> 1)) begin
                        if (!rx_s) begin st <= DATA; cnt <= 16'd0; bit_idx <= 3'd0; end
                        else st <= IDLE;   // glitch
                    end else cnt <= cnt + 16'd1;
                end
                DATA: begin
                    if (cnt == clk_div - 16'd1) begin
                        cnt <= 16'd0;
                        sh  <= {rx_s, sh[7:1]};
                        if (bit_idx == 3'd7) st <= STOP;
                        else bit_idx <= bit_idx + 3'd1;
                    end else cnt <= cnt + 16'd1;
                end
                STOP: begin
                    if (cnt == clk_div - 16'd1) begin
                        st    <= IDLE;
                        data  <= sh;
                        valid <= rx_s;   // require valid stop bit
                    end else cnt <= cnt + 16'd1;
                end
            endcase
        end
    end
endmodule : uart_rx
