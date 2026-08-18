`default_nettype none
`timescale 1ns/1ps
// gpio test: write and read the OUT and OE registers, read the IN pins, and
// verify gpio_out/gpio_oe track the registers.
module tb_gpio;
    logic clk=0, rst=1, we=0; logic [3:0] addr=0; logic [31:0] wdata=0, rdata;
    logic [31:0] gpio_out, gpio_in=0, gpio_oe;
    gpio dut(.clk(clk),.rst(rst),.addr(addr),.wdata(wdata),.we(we),.rdata(rdata),
        .gpio_out(gpio_out),.gpio_in(gpio_in),.gpio_oe(gpio_oe));
    always #5 clk=~clk;
    integer errors=0, tests=0, k;
    logic [31:0] mo, moe, v;
    task wrreg(input [3:0] a, input [31:0] d); begin
        @(negedge clk); addr=a; wdata=d; we=1; @(negedge clk); we=0;
    end endtask
    task rdchk(input [3:0] a, input [31:0] exp); begin
        @(negedge clk); addr=a; #1; tests=tests+1;
        if (rdata !== exp) begin errors=errors+1;
            if(errors<=5) $display("  GPIO MISMATCH addr=%0d got=%h exp=%h",a,rdata,exp); end
    end endtask
    initial begin
        mo=0; moe=0;
        @(negedge clk); rst=0;
        for(k=0;k<500;k=k+1) begin
            v=$random;
            wrreg(4'h0, v); mo=v;                       // OUT
            rdchk(4'h0, mo);
            if (gpio_out!==mo) begin errors=errors+1; $display("  gpio_out mismatch"); end
            v=$random; wrreg(4'h2, v); moe=v;           // OE
            rdchk(4'h2, moe);
            if (gpio_oe!==moe) begin errors=errors+1; $display("  gpio_oe mismatch"); end
            gpio_in=$random; rdchk(4'h1, gpio_in);      // IN reads pins
        end
        $display("gpio: %0d tests, %0d errors -> %s", tests, errors, errors?"FAIL":"PASS");
        $finish;
    end
endmodule
