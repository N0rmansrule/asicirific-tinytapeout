// mem_bus.sv — routes the core's single memory port to the right target.
// Address map: 0x00xxxxxx flash (read-only program), 0x01xxxxxx PSRAM (data),
// 0x02xxxxxx GPIO (on-chip, one cycle). Flash and PSRAM go through the QSPI
// controller and take many cycles; GPIO answers immediately. The core waits on
// ready either way.
`default_nettype none

module mem_bus (
    input  wire logic        clk,
    input  wire logic        rst,
    // from core
    input  wire logic [31:0] c_addr,
    input  wire logic [31:0] c_wdata,
    input  wire logic [3:0]  c_be,
    input  wire logic        c_we,
    input  wire logic        c_re,
    output logic [31:0]      c_rdata,
    output logic             c_ready,
    // to QSPI controller
    output logic [31:0]      m_addr,
    output logic [31:0]      m_wdata,
    output logic [3:0]       m_be,
    output logic             m_we,
    output logic             m_re,
    input  wire logic [31:0] m_rdata,
    input  wire logic        m_ready,
    // to GPIO
    output logic [3:0]       g_addr,
    output logic [31:0]      g_wdata,
    output logic             g_we,
    input  wire logic [31:0] g_rdata,
    // pins for GPIO handled at the top level
    output logic             sel_gpio_o
);
    wire is_gpio = (c_addr[31:24] == 8'h02);

    assign sel_gpio_o = is_gpio;

    // QSPI path only sees flash/PSRAM accesses
    assign m_addr  = c_addr;
    assign m_wdata = c_wdata;
    assign m_be    = c_be;
    assign m_we    = c_we && !is_gpio;
    assign m_re    = c_re && !is_gpio;

    // GPIO path
    assign g_addr  = c_addr[5:2];
    assign g_wdata = c_wdata;
    assign g_we    = c_we && is_gpio;

    // GPIO answers in one cycle; register a ready pulse for it
    logic gpio_ready;
    always_ff @(posedge clk) begin
        if (rst) gpio_ready <= 1'b0;
        else     gpio_ready <= (c_re || c_we) && is_gpio && !gpio_ready;
    end

    assign c_rdata = is_gpio ? g_rdata : m_rdata;
    assign c_ready = is_gpio ? gpio_ready : m_ready;
endmodule : mem_bus
