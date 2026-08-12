// uart_boot.sv — serial download bootloader (the ESP32-classic path).
//
// While the core is held in reset, this FSM listens on the UART receiver for a
// framed program, writes it word-by-word into the boot SRAM, and then releases
// the core so it runs from RESET_PC. This is exactly how the classic ESP32 (and
// Arduino, and many MCUs) get "programmed over USB": a USB-to-UART bridge on the
// board turns USB-C into a serial stream, and this loader speaks that stream.
//
// It shares the SRAM write port with the debug system bus and the core; the
// containing SoC gives the bootloader top priority while boot_active is high.
//
// Frame (all multi-byte fields little-endian):
//   'A' 'S' 'I' 'C'           4-byte magic sync
//   count[31:0]               number of 32-bit words that follow
//   word[0] .. word[count-1]  the program image (loaded from SRAM word 0)
//   check[31:0]               32-bit sum of all words (mod 2^32)
// Status byte on TX: 0x9D = done-OK, 0xEE = checksum error (host may retry).
`default_nettype none

module uart_boot #(
    parameter int unsigned AW = 9
)(
    input  wire logic        clk,
    input  wire logic        rst,
    input  wire logic        boot_sel,             // 1 at reset = enter loader

    input  wire logic        rx_valid,
    input  wire logic [7:0]  rx_data,
    output logic             tx_start,
    output logic [7:0]       tx_data,
    input  wire logic        tx_busy,

    output logic             mem_we,
    output logic [AW-1:0]    mem_addr,
    output logic [31:0]      mem_wdata,

    output logic             boot_active,
    output logic             boot_done,
    output logic             boot_err
);
    localparam logic [7:0] MAGIC0 = 8'h41, MAGIC1 = 8'h53, MAGIC2 = 8'h49, MAGIC3 = 8'h43;
    localparam logic [3:0] B_IDLE=0, B_M1=1, B_M2=2, B_M3=3, B_COUNT=4,
                           B_DATA=5, B_CHECK=6, B_REPORT=7, B_RUN=8;

    logic [3:0]    st;
    logic [1:0]    bcnt;         // byte index within a 4-byte field
    logic [31:0]   shreg;        // 4-byte little-endian assembly (complete after 4 bytes)
    logic          full;        // pulses when shreg holds a complete word
    logic [AW-1:0] wr_word;      // SRAM word index
    logic [31:0]   words_left, checksum, check_rx;
    logic          boot_ok;
    logic [7:0]    status_code;
    logic          status_send;

    always_ff @(posedge clk) begin
        mem_we    <= 1'b0;
        boot_done <= 1'b0;
        boot_err  <= 1'b0;
        full      <= 1'b0;

        if (rst) begin
            st <= boot_sel ? B_IDLE : B_RUN;
            boot_active <= boot_sel;
            bcnt <= 2'd0; wr_word <= '0; checksum <= '0;
        end else begin
            case (st)
                B_IDLE: begin
                    boot_active <= 1'b1;
                    if (rx_valid && rx_data == MAGIC0) st <= B_M1;
                end
                B_M1: if (rx_valid) st <= (rx_data==MAGIC1) ? B_M2 : B_IDLE;
                B_M2: if (rx_valid) st <= (rx_data==MAGIC2) ? B_M3 : B_IDLE;
                B_M3: if (rx_valid) begin
                    if (rx_data==MAGIC3) begin st <= B_COUNT; bcnt <= 2'd0; end
                    else st <= B_IDLE;
                end
                B_COUNT: begin
                    if (rx_valid) begin
                        shreg <= {rx_data, shreg[31:8]};
                        full  <= (bcnt == 2'd3);
                        bcnt  <= (bcnt == 2'd3) ? 2'd0 : bcnt + 2'd1;
                    end
                    if (full) begin
                        words_left <= shreg;
                        checksum   <= 32'd0;
                        wr_word    <= '0;
                        st         <= B_DATA;
                    end
                end
                B_DATA: begin
                    if (rx_valid) begin
                        shreg <= {rx_data, shreg[31:8]};
                        full  <= (bcnt == 2'd3);
                        bcnt  <= (bcnt == 2'd3) ? 2'd0 : bcnt + 2'd1;
                    end
                    if (full) begin
                        mem_we     <= 1'b1;
                        mem_addr   <= wr_word;
                        mem_wdata  <= shreg;
                        wr_word    <= wr_word + 1'b1;
                        checksum   <= checksum + shreg;
                        words_left <= words_left - 32'd1;
                        if (words_left == 32'd1) st <= B_CHECK;
                    end
                end
                B_CHECK: begin
                    if (rx_valid) begin
                        shreg <= {rx_data, shreg[31:8]};
                        full  <= (bcnt == 2'd3);
                        bcnt  <= (bcnt == 2'd3) ? 2'd0 : bcnt + 2'd1;
                    end
                    if (full) begin
                        check_rx <= shreg;
                        boot_ok  <= (shreg == checksum);
                        st       <= B_REPORT;
                    end
                end
                B_REPORT: begin
                    status_code <= boot_ok ? 8'h9D : 8'hEE;
                    status_send <= 1'b1;
                    if (boot_ok) begin
                        boot_done   <= 1'b1;
                        boot_active <= 1'b0;
                        st          <= B_RUN;
                    end else begin
                        boot_err <= 1'b1;
                        st       <= B_IDLE;
                    end
                end
                B_RUN: boot_active <= 1'b0;
                default: st <= B_IDLE;
            endcase
        end
    end

    // separate TX status pusher keeps the FSM off the tx_start net
    always_ff @(posedge clk) begin
        tx_start <= 1'b0;
        if (rst) status_send <= 1'b0;
        else if (status_send && !tx_busy) begin
            tx_data     <= status_code;
            tx_start    <= 1'b1;
            status_send <= 1'b0;
        end
    end
endmodule : uart_boot
