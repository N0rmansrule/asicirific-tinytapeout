`default_nettype none
`timescale 1ns/1ps
// spi_mem test: drive the controller directly and check it reads from the flash
// model, writes and reads back the PSRAM model (word and byte via read-modify-
// write), all over the real single-bit SPI protocol.
module tb_spi_mem;
    logic clk=0, rst=1; always #5 clk=~clk;
    logic [31:0] addr=0,wdata=0,rdata; logic [3:0] be=4'hF; logic re=0,we=0,ready;
    logic sck,sd0,sd1,csf,csr;
    spi_mem dut(.clk(clk),.rst(rst),.addr(addr),.re(re),.we(we),.wdata(wdata),.be(be),
        .rdata(rdata),.ready(ready),.sck(sck),.sd0(sd0),.sd1(sd1),.cs_flash_n(csf),.cs_ram_n(csr));
    wire sd1_f,sd1_r; assign sd1=(!csf)?sd1_f:(!csr)?sd1_r:1'b0;
    spi_flash flash(.clk(clk),.cs_n(csf),.sck(sck),.sd0(sd0),.sd1(sd1_f));
    spi_psram psram(.clk(clk),.cs_n(csr),.sck(sck),.sd0(sd0),.sd1(sd1_r));
    integer errors=0, tests=0, k;
    logic [31:0] got, ex;

    task do_read(input [31:0] a); begin
        @(negedge clk); addr=a; re=1;
        wait(ready); @(negedge clk); got=rdata; re=0; @(negedge clk);
    end endtask
    task do_write(input [31:0] a, input [31:0] d, input [3:0] b); begin
        @(negedge clk); addr=a; wdata=d; be=b; we=1;
        wait(ready); @(negedge clk); we=0; be=4'hF; @(negedge clk);
    end endtask

    initial begin
        // preload flash + psram
        for(k=0;k<32;k=k+1) begin flash.mem[k]=32'h1000_0000+k; psram.mem[k]=32'hCAFE0000+k; end
        @(negedge clk); rst=0; @(negedge clk);
        // flash reads
        do_read(32'h0000_0000); tests=tests+1; if(got!==32'h1000_0000) begin errors++; $display("  flash[0] got=%h",got); end
        do_read(32'h0000_0008); tests=tests+1; if(got!==32'h1000_0002) begin errors++; $display("  flash[2] got=%h",got); end
        // psram reads (region 0x01)
        do_read(32'h0100_0000); tests=tests+1; if(got!==32'hCAFE0000) begin errors++; $display("  psram[0] got=%h",got); end
        do_read(32'h0100_0004); tests=tests+1; if(got!==32'hCAFE0001) begin errors++; $display("  psram[1] got=%h",got); end
        // psram word write then read back
        do_write(32'h0100_0010, 32'h12345678, 4'hF);
        do_read(32'h0100_0010); tests=tests+1; if(got!==32'h12345678) begin errors++; $display("  psram wr/rd got=%h",got); end
        // psram byte write (RMW): change byte 1 of the word to 0xAB
        do_write(32'h0100_0010, 32'h0000AB00, 4'b0010);
        do_read(32'h0100_0010); tests=tests+1; ex=32'h1234AB78;
        if(got!==ex) begin errors++; $display("  psram byte RMW got=%h exp=%h",got,ex); end
        $display("spi_mem: %0d tests, %0d errors -> %s", tests, errors, errors?"FAIL":"PASS");
        $finish;
    end
endmodule
