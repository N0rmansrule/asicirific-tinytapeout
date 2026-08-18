`default_nettype none
`timescale 1ns/1ps
// serial_core integration test: run a program that exercises arithmetic, logic,
// shifts, branches, a loop, a jump, and memory (store then load), then check the
// final register and memory state. This is the whole CPU end to end (with a fast
// 1-cycle memory so it runs quickly).
module tb_serial_core;
    logic clk=0, rst=1; always #5 clk=~clk;
    logic [31:0] a,wd,rdt; logic [3:0] be; logic we,re,rdy;
    serial_core #(.RESET_PC(32'h0)) dut(.clk(clk),.rst(rst),.mem_addr(a),.mem_wdata(wd),
        .mem_be(be),.mem_we(we),.mem_re(re),.mem_rdata(rdt),.mem_ready(rdy));
    logic [31:0] mem [0:255]; logic pend; integer kk;
    assign rdt = mem[a[9:2]]; assign rdy = pend;
    always_ff @(posedge clk) begin
        if(rst) pend<=0; else pend <= (re|we) & ~pend;
        if(!rst && we && pend) for(kk=0;kk<4;kk=kk+1) if(be[kk]) mem[a[9:2]][kk*8+:8]<=wd[kk*8+:8];
    end
    integer i;
    initial begin
        for(i=0;i<256;i=i+1) mem[i]=32'h00000013;
        // sum 1..10, shift, store, load, verify
        mem[0]=32'h00000093; // addi x1,x0,0   sum
        mem[1]=32'h00100113; // addi x2,x0,1   i
        mem[2]=32'h00b00193; // addi x3,x0,11  limit
        mem[3]=32'h002080b3; // add  x1,x1,x2
        mem[4]=32'h00110113; // addi x2,x2,1
        mem[5]=32'hfe314ce3; // blt  x2,x3,-8   (loop)  sum=55
        mem[6]=32'h00209213; // slli x4,x1,2    55<<2=220
        mem[7]=32'h10000293; // addi x5,x0,256   data addr 0x100
        mem[8]=32'h0042a023; // sw   x4,0(x5)    store 220
        mem[9]=32'h0002a303; // lw   x6,0(x5)    load -> 220
        mem[10]=32'h4062d393;// srai x7,x5,6? -> just something; use andi
        mem[10]=32'h0ff37393;// andi x7,x6,0xff  220&0xff=220
        mem[11]=32'h0000006f;// j .
        repeat(3) @(posedge clk); rst=0;
        for(i=0;i<20000;i=i+1) begin @(posedge clk);
            if (a==32'h2c && dut.st==0 && rdy) begin
                $display("  x1(sum)=%0d[55] x4(shl)=%0d[220] x6(lw)=%0d[220] x7(and)=%0d[220]",
                  dut.u_rf.sr[1],dut.u_rf.sr[4],dut.u_rf.sr[6],dut.u_rf.sr[7]);
                if(dut.u_rf.sr[1]==55 && dut.u_rf.sr[4]==220 && dut.u_rf.sr[6]==220 &&
                   dut.u_rf.sr[7]==220 && mem[64]==220)
                    $display("serial_core: PASS"); else $display("serial_core: FAIL");
                $finish;
            end
        end
        $display("serial_core: FAIL (timeout st=%0d pc=%h)",dut.st,dut.pc); $finish;
    end
endmodule
