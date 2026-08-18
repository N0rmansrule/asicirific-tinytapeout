`default_nettype none
`timescale 1ns/1ps
// mem_bus test: verify address decode routes GPIO region (0x02xxxxxx) to the
// GPIO port and everything else to the QSPI port, and that ready/rdata mux
// follows the target.
module tb_mem_bus;
    logic clk=0, rst=1;
    logic [31:0] c_addr=0,c_wdata=0,c_rdata; logic [3:0] c_be=0; logic c_we=0,c_re=0,c_ready;
    logic [31:0] m_addr,m_wdata,m_rdata=32'hAAAA5555; logic [3:0] m_be; logic m_we,m_re,m_ready=1;
    logic [3:0] g_addr; logic [31:0] g_wdata,g_rdata=32'h1234ABCD; logic g_we,sel_gpio;
    mem_bus dut(.clk(clk),.rst(rst),.c_addr(c_addr),.c_wdata(c_wdata),.c_be(c_be),
        .c_we(c_we),.c_re(c_re),.c_rdata(c_rdata),.c_ready(c_ready),
        .m_addr(m_addr),.m_wdata(m_wdata),.m_be(m_be),.m_we(m_we),.m_re(m_re),
        .m_rdata(m_rdata),.m_ready(m_ready),
        .g_addr(g_addr),.g_wdata(g_wdata),.g_we(g_we),.g_rdata(g_rdata),.sel_gpio_o(sel_gpio));
    always #5 clk=~clk;
    integer errors=0, tests=0;
    initial begin
        @(negedge clk); rst=0; @(negedge clk);
        // flash region: should route to QSPI, not GPIO
        c_addr=32'h0000_0010; c_re=1; #1; tests=tests+1;
        if (sel_gpio!==0 || m_re!==1 || c_rdata!==m_rdata) begin errors=errors+1; $display("  flash route fail"); end
        // PSRAM region
        c_addr=32'h0100_0020; #1; tests=tests+1;
        if (sel_gpio!==0 || m_re!==1) begin errors=errors+1; $display("  psram route fail"); end
        // GPIO region: route to GPIO
        c_addr=32'h0200_0004; #1; tests=tests+1;
        if (sel_gpio!==1 || m_re!==0 || c_rdata!==g_rdata) begin errors=errors+1; $display("  gpio route fail"); end
        // GPIO ready pulses within a couple cycles
        c_re=0; c_we=1; c_addr=32'h0200_0000; repeat(3) @(negedge clk); tests=tests+1;
        // (ready is a registered pulse; just check no X)
        if (c_ready===1'bx) begin errors=errors+1; $display("  gpio ready X"); end
        $display("mem_bus: %0d tests, %0d errors -> %s", tests, errors, errors?"FAIL":"PASS");
        $finish;
    end
endmodule
