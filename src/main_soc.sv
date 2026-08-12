// main_soc.sv — main domain: six-stage core + boot SRAM (unified I/D for TT)
// + UART + GPIO, plus a JTAG debug port whose system bus can load the SRAM.
// Memory map (subset active in TT): SRAM @ 0x1000_0000, periphs @ 0x2000_xxxx.
`default_nettype none
module main_soc #(
    parameter int unsigned RAM_WORDS = 512,
    parameter bit          RV32M     = 1'b1     // set 0 for the tile (RV32I, smaller)
)(
    input  wire logic clk,
    input  wire logic rst,

    // UART pins
    output logic uart_tx,
    input  wire logic uart_rx,
    // GPIO
    output logic [7:0] gpio_out,
    input  wire logic [7:0] gpio_in,
    output logic [7:0] gpio_oe,
    // JTAG
    input  wire logic tck, tms, tdi, trst_n,
    output logic tdo, tdo_oe,
    // serial bootloader (USB-C via USB-UART bridge, ESP32-style)
    input  wire logic boot_sel,        // BOOT pin: 1 at reset = enter download mode
    output logic      boot_active,     // high while downloading (core held in reset)
    output logic      boot_done        // pulses when a good image has loaded
);
    localparam int AW = $clog2(RAM_WORDS);

    // ---- core memory buses ----
    logic [31:0] imem_addr, imem_rdata;
    logic [31:0] dmem_addr, dmem_wdata, dmem_rdata;
    logic [3:0]  dmem_be;
    logic        dmem_we, dmem_re;
    logic        dbg_halt_req, dbg_halted;

    // Core is held in reset until the bootloader releases it. We latch the
    // release so a glitch on boot_active can't restart the core mid-run, and so
    // the first fetch happens only after the image is fully in SRAM.
    // Release sequence: on boot_done, hold the core in reset for a few more
    // cycles (so the loaded SRAM and the fetch mux are fully settled), then
    // deassert reset once. This gives the pipeline a clean, glitch-free start
    // from RESET_PC, exactly like a fresh power-on with the program already in.
    logic       booted;         // a good image is in SRAM
    logic [3:0] settle;
    logic       core_run;        // 1 = let the core run
    always_ff @(posedge clk) begin
        if (rst) begin
            booted   <= ~boot_sel;   // boot_sel low = run immediately
            settle   <= 4'd8;
            core_run <= 1'b0;
        end else begin
            if (boot_done) booted <= 1'b1;
            if (booted) begin
                if (settle != 4'd0) settle <= settle - 4'd1;
                else                core_run <= 1'b1;
            end
        end
    end
    wire logic core_released = core_run;          // used by the fetch-mux qualifiers
    wire logic core_rst      = rst || !core_run;

    core_top #(.RESET_PC(32'h1000_0000), .ENABLE_BP(1'b1), .ENABLE_M(RV32M)) u_core (
        .clk(clk), .rst(core_rst),
        .imem_addr(imem_addr), .imem_rdata(imem_rdata),
        .dmem_addr(dmem_addr), .dmem_wdata(dmem_wdata),
        .dmem_be(dmem_be), .dmem_we(dmem_we), .dmem_re(dmem_re),
        .dmem_rdata(dmem_rdata),
        .dbg_halt_req(dbg_halt_req), .dbg_halted(dbg_halted)
    );

    // ---- serial bootloader (ESP32-style download over UART) ----
    // Dedicated RX/TX for the loader, sharing the physical pins. During download
    // the loader owns the TX pin; afterward the MMIO UART owns it.
    logic        brx_valid;
    logic [7:0]  brx_data;
    logic        btx_start, btx_busy;
    logic [7:0]  btx_data;
    logic        boot_we;
    logic [AW-1:0] boot_addr;
    logic [31:0] boot_wdata;
    logic        btx_pin, mtx_pin;

    // fixed boot baud divider (115200 @ 25 MHz ~ 217); tune per clock
    localparam logic [15:0] BOOT_DIV = 16'd217;

    uart_rx u_brx (
        .clk(clk), .rst(rst), .clk_div(BOOT_DIV), .rx(uart_rx),
        .valid(brx_valid), .data(brx_data)
    );
    uart_tx u_btx (
        .clk(clk), .rst(rst), .clk_div(BOOT_DIV),
        .start(btx_start), .data(btx_data), .busy(btx_busy), .tx(btx_pin)
    );

    uart_boot #(.AW(AW)) u_boot (
        .clk(clk), .rst(rst), .boot_sel(boot_sel),
        .rx_valid(brx_valid), .rx_data(brx_data),
        .tx_start(btx_start), .tx_data(btx_data), .tx_busy(btx_busy),
        .mem_we(boot_we), .mem_addr(boot_addr), .mem_wdata(boot_wdata),
        .boot_active(boot_active), .boot_done(boot_done), .boot_err()
    );

    // TX pin mux: loader drives it while active, else the MMIO UART
    assign uart_tx = boot_active ? btx_pin : mtx_pin;

    // ---- debug system bus (loads SRAM over JTAG) ----
    logic        sb_re, sb_we;
    logic [31:0] sb_addr, sb_wdata, sb_rdata;

    debug_top u_dbg (
        .tck(tck), .tms(tms), .tdi(tdi), .trst_n(trst_n),
        .tdo(tdo), .tdo_oe(tdo_oe),
        .halt_req(dbg_halt_req), .halted(dbg_halted),
        .sb_re(sb_re), .sb_we(sb_we), .sb_addr(sb_addr),
        .sb_wdata(sb_wdata), .sb_rdata(sb_rdata)
    );

    // ---- address decode for data side ----
    wire logic is_ram_d  = (dmem_addr[31:28] == 4'h1);
    wire logic is_peri_d = (dmem_addr[31:16] == 16'h2000);
    logic [4:0] psel;
    bus_fabric u_fab (.addr(dmem_addr), .sel(psel));

    // ---- unified SRAM: serves boot download, instruction fetch, data, debug ----
    // Priority: bootloader > debug sysbus > data > instruction.
    logic [AW-1:0] ram_addr;
    logic [31:0]   ram_wdata, ram_rdata;
    logic [3:0]    ram_be;
    logic          ram_we;
    logic          use_dbg, use_data;

    // qualify core-driven accesses with core_released so undefined core outputs
    // during reset/download cannot leak X into the fetch mux
    assign use_dbg  = core_released && (sb_we || sb_re);
    assign use_data = core_released && (dmem_we || (dmem_re && is_ram_d));

    always_comb begin
        if (boot_we) begin
            ram_addr  = boot_addr;
            ram_wdata = boot_wdata;
            ram_be    = 4'b1111;
            ram_we    = 1'b1;
        end else if (use_dbg) begin
            ram_addr  = sb_addr[AW+1:2];
            ram_wdata = sb_wdata;
            ram_be    = 4'b1111;
            ram_we    = sb_we;
        end else if (use_data) begin
            ram_addr  = dmem_addr[AW+1:2];
            ram_wdata = dmem_wdata;
            ram_be    = dmem_be;
            ram_we    = dmem_we && is_ram_d;
        end else begin
            ram_addr  = imem_addr[AW+1:2];   // instruction fetch
            ram_wdata = 32'd0;
            ram_be    = 4'b0000;
            ram_we    = 1'b0;
        end
    end

    spram #(.WORDS(RAM_WORDS)) u_ram (
        .clk(clk), .addr(ram_addr), .wdata(ram_wdata),
        .be(ram_be), .we(ram_we), .rdata(ram_rdata)
    );

    // instruction read returns RAM data when not preempted; else a bubble (NOP)
    logic preempt_d, preempt_q;
    // X-safe: only preempt on a strobe that is *known* high; an undefined strobe
    // (e.g. a core output during pipeline fill) counts as no-preempt.
    always_comb preempt_d = (use_dbg  === 1'b1)
                         || (use_data === 1'b1)
                         || (boot_we  === 1'b1);
    always_ff @(posedge clk)
        if (rst) preempt_q <= 1'b1;
        else     preempt_q <= preempt_d;
    assign imem_rdata = preempt_q ? 32'h0000_0013 : ram_rdata;  // 0x13 = addi x0,x0,0
    assign sb_rdata   = ram_rdata;

    // ---- peripherals ----
    logic [31:0] uart_rd, gpio_rd;
    uart u_uart (
        .clk(clk), .rst(rst), .addr(dmem_addr[3:0]), .wdata(dmem_wdata),
        .we(dmem_we && psel[0]), .re(dmem_re && psel[0]),
        .rdata(uart_rd), .tx(mtx_pin), .rx(uart_rx)
    );
    gpio u_gpio (
        .clk(clk), .rst(rst), .addr(dmem_addr[3:0]), .wdata(dmem_wdata),
        .we(dmem_we && psel[1]), .rdata(gpio_rd),
        .gpio_out(gpio_out), .gpio_in(gpio_in), .gpio_oe(gpio_oe)
    );

    // ---- data read mux (registered to match sync SRAM timing) ----
    logic [4:0]  psel_q;
    logic        is_ram_q;
    always_ff @(posedge clk) begin
        psel_q   <= psel;
        is_ram_q <= is_ram_d;
    end
    always_comb begin
        if (is_ram_q)        dmem_rdata = ram_rdata;
        else if (psel_q[0])  dmem_rdata = uart_rd;
        else if (psel_q[1])  dmem_rdata = gpio_rd;
        else                 dmem_rdata = 32'd0;
    end
endmodule : main_soc
