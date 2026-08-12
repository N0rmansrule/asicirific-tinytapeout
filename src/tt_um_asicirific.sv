// tt_um_asicirific.sv — TinyTapeout submission top for the ASICirific subset.
//
// This is the "Tile A" right-sized build: a single RV32I core (M-extension
// disabled to save area) with a boot SRAM, UART, GPIO, JTAG debug, and the
// USB-C-style serial bootloader. It maps onto the fixed TinyTapeout pin
// interface. The full ASICirific (six-stage RV32IM + FHE + secure enclave +
// ADC/DAC) lives in the sibling `asicirific/` project and targets a larger MPW.
//
// Pin map
// -------
//   ui_in[0]      uart_rx        (serial from USB-UART bridge, host -> chip)
//   ui_in[1]      BOOT           (high at reset = enter USB download mode)
//   ui_in[2]      gpio_in[0]
//   ui_in[3]      gpio_in[1]
//   ui_in[4]      gpio_in[2]
//   ui_in[7:5]    unused (tie low)
//
//   uo_out[0]     uart_tx        (serial to host)
//   uo_out[1]     boot_active    (high while downloading)
//   uo_out[2]     tdo            (JTAG data out)
//   uo_out[7:3]   gpio_out[4:0]
//
//   uio[0]        tck   (JTAG, input)
//   uio[1]        tms   (JTAG, input)
//   uio[2]        tdi   (JTAG, input)
//   uio[3]        trst_n(JTAG, input)
//   uio[4]        gpio_out[5]  (output)
//   uio[5]        gpio_out[6]  (output)
//   uio[6]        gpio_out[7]  (output)
//   uio[7]        boot_done    (output)
//
// TinyTapeout convention: outputs are only meaningful while `ena` is high; we
// keep the design running and gate nothing on `ena` (kept for harness compliance).
`default_nettype none

module tt_um_asicirific (
    input  wire [7:0] ui_in,     // dedicated inputs
    output wire [7:0] uo_out,    // dedicated outputs
    input  wire [7:0] uio_in,    // bidirectional: input path
    output wire [7:0] uio_out,   // bidirectional: output path
    output wire [7:0] uio_oe,    // bidirectional: output enable (1 = drive)
    input  wire       ena,       // high when the design is selected
    input  wire       clk,       // system clock
    input  wire       rst_n      // active-low reset
);
    wire rst = ~rst_n;

    // ---- main-domain signals ----
    wire        m_uart_tx, m_tdo, m_tdo_oe;
    wire        m_boot_active, m_boot_done;
    wire [7:0]  m_gpio_out, m_gpio_in, m_gpio_oe;

    assign m_gpio_in = {5'd0, ui_in[4:2]};

    main_soc #(
        .RAM_WORDS(512),
        .RV32M(1'b0)          // RV32I on the tile to fit the gate budget
    ) u_soc (
        .clk(clk), .rst(rst),
        .uart_tx(m_uart_tx), .uart_rx(ui_in[0]),
        .gpio_out(m_gpio_out), .gpio_in(m_gpio_in), .gpio_oe(m_gpio_oe),
        .tck(uio_in[0]), .tms(uio_in[1]), .tdi(uio_in[2]), .trst_n(uio_in[3]),
        .tdo(m_tdo), .tdo_oe(m_tdo_oe),
        .boot_sel(ui_in[1]),
        .boot_active(m_boot_active), .boot_done(m_boot_done)
    );

    // ---- dedicated outputs ----
    assign uo_out[0]   = m_uart_tx;
    assign uo_out[1]   = m_boot_active;
    assign uo_out[2]   = m_tdo;
    assign uo_out[7:3] = m_gpio_out[4:0];

    // ---- bidirectional bank ----
    // uio[0:3] JTAG inputs; uio[4:7] outputs
    assign uio_oe      = 8'b1111_0000;
    assign uio_out[0]  = 1'b0;
    assign uio_out[1]  = 1'b0;
    assign uio_out[2]  = 1'b0;
    assign uio_out[3]  = 1'b0;
    assign uio_out[4]  = m_gpio_out[5];
    assign uio_out[5]  = m_gpio_out[6];
    assign uio_out[6]  = m_gpio_out[7];
    assign uio_out[7]  = m_boot_done;

    // tie off unused so the linter is quiet
    wire _unused = &{ena, ui_in[7:5], m_tdo_oe, m_gpio_oe, 1'b0};
endmodule : tt_um_asicirific
