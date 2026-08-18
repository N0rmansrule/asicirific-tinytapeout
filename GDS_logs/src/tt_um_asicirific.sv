// tt_um_asicirific.sv — bit-serial RV32E microcontroller for TinyTapeout.
//
// The whole computer on one chip: a bit-serial RV32E CPU, a QSPI controller for
// external flash (program) and PSRAM (data), and a GPIO block for buttons and
// sensor lines. Serial, SPI, and I2C are bit-banged in software over GPIO, so no
// peripheral hardware spends tile area. Programs are flashed over USB-C by the
// demo board's RP2040 writing the external flash; the CPU runs from it on reset.
//
// Pin map (24 I/O)
// ----------------
//   uio[0..3]  QSPI SD0-SD3 (shared flash/PSRAM data, bidirectional)
//   uio[4]     QSPI SCK
//   uio[5]     QSPI CS_flash (active low)
//   uio[6]     QSPI CS_ram   (active low)
//   uio[7]     gpio_out[8] / spare
//   ui_in[0..7]   GPIO inputs  gpio_in[0..7]   (buttons)
//   uo_out[0..7]  GPIO outputs gpio_out[0..7]  (LEDs, sensor control)
`default_nettype none

module tt_um_asicirific (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);
    wire rst = ~rst_n;

    // ---- core <-> bus ----
    wire [31:0] c_addr, c_wdata, c_rdata;
    wire [3:0]  c_be;
    wire        c_we, c_re, c_ready;

    serial_core #(.RESET_PC(32'h0000_0000)) u_core (
        .clk(clk), .rst(rst),
        .mem_addr(c_addr), .mem_wdata(c_wdata), .mem_be(c_be),
        .mem_we(c_we), .mem_re(c_re), .mem_rdata(c_rdata), .mem_ready(c_ready)
    );

    // ---- bus <-> QSPI + GPIO ----
    wire [31:0] m_addr, m_wdata, m_rdata;
    wire [3:0]  m_be;
    wire        m_we, m_re, m_ready;
    wire [3:0]  g_addr;
    wire [31:0] g_wdata, g_rdata;
    wire        g_we, sel_gpio;

    mem_bus u_bus (
        .clk(clk), .rst(rst),
        .c_addr(c_addr), .c_wdata(c_wdata), .c_be(c_be),
        .c_we(c_we), .c_re(c_re), .c_rdata(c_rdata), .c_ready(c_ready),
        .m_addr(m_addr), .m_wdata(m_wdata), .m_be(m_be),
        .m_we(m_we), .m_re(m_re), .m_rdata(m_rdata), .m_ready(m_ready),
        .g_addr(g_addr), .g_wdata(g_wdata), .g_we(g_we), .g_rdata(g_rdata),
        .sel_gpio_o(sel_gpio)
    );

    // ---- QSPI controller ----
    wire spi_sck, spi_sd0, spi_sd1, cs_flash_n, cs_ram_n;
    spi_mem u_spi (
        .clk(clk), .rst(rst),
        .addr(m_addr), .re(m_re), .we(m_we), .wdata(m_wdata), .be(m_be),
        .rdata(m_rdata), .ready(m_ready),
        .sck(spi_sck), .sd0(spi_sd0), .sd1(spi_sd1),
        .cs_flash_n(cs_flash_n), .cs_ram_n(cs_ram_n)
    );

    // ---- GPIO ----
    wire [31:0] gpio_out, gpio_in, gpio_oe;
    assign gpio_in = {24'd0, ui_in};
    gpio u_gpio (
        .clk(clk), .rst(rst), .addr(g_addr), .wdata(g_wdata), .we(g_we),
        .rdata(g_rdata), .gpio_out(gpio_out), .gpio_in(gpio_in), .gpio_oe(gpio_oe)
    );

    // ---- pins ----
    // outputs: GPIO out[7:0]
    assign uo_out = gpio_out[7:0];

    // bidirectional bank: QSPI on uio[6:0], spare GPIO on uio[7]
    // SD0-3 are true bidirectional; the controller drives sd0 and reads sd1.
    assign uio_out[0] = spi_sd0;        // SD0: chip data in (we drive)
    assign uio_out[1] = 1'b0;           // SD1: chip data out (we read uio_in[1])
    assign uio_out[2] = 1'b0;           // SD2 held low (unused in single-bit SPI)
    assign uio_out[3] = 1'b0;           // SD3 held low
    assign uio_out[4] = spi_sck;
    assign uio_out[5] = cs_flash_n;
    assign uio_out[6] = cs_ram_n;
    assign uio_out[7] = gpio_out[8];

    // direction: drive SD0, SCK, CS, and the spare GPIO; SD1 is an input
    assign uio_oe[0] = 1'b1;            // SD0 out
    assign uio_oe[1] = 1'b0;            // SD1 in
    assign uio_oe[2] = 1'b1;
    assign uio_oe[3] = 1'b1;
    assign uio_oe[4] = 1'b1;            // SCK
    assign uio_oe[5] = 1'b1;            // CS_flash
    assign uio_oe[6] = 1'b1;            // CS_ram
    assign uio_oe[7] = 1'b1;            // spare GPIO out

    assign spi_sd1 = uio_in[1];

    wire _unused = &{ena, gpio_oe, gpio_in[31:8], uio_in[0], uio_in[7:2], 1'b0};
endmodule : tt_um_asicirific
