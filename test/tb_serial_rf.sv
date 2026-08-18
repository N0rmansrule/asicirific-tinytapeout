`default_nettype none
`timescale 1ns/1ps
// Thorough serial_rf test. Stimulus is driven on the negedge so it is stable at
// the active posedge (avoids clock races). Writes random values into every
// register, reads them back, checks x0 stays zero, over many passes.
module tb_serial_rf;
    logic clk=0, rst=1, en=0, we=0, wbit=0, shl=0, shr=0, shin=0;
    logic [3:0] rs1=0, rs2=0, rd=0; logic o1, o2, rmsb;
    serial_rf dut(.clk(clk),.rst(rst),.en(en),.rs1(rs1),.rs2(rs2),.rd(rd),
        .we(we),.wbit(wbit),.shl(shl),.shr(shr),.shin(shin),
        .rs1_bit(o1),.rs2_bit(o2),.rd_msb(rmsb));
    always #5 clk=~clk;
    integer errors=0, tests=0, i, j, pass;
    logic [31:0] model [15:0];
    logic [31:0] rv, got;

    task wr(input [3:0] r, input [31:0] v); begin
        for(i=0;i<32;i=i+1) begin
            @(negedge clk); rd=r; we=1; en=1; wbit=v[i];
        end
        @(negedge clk); we=0; en=0;
        if(r!=0) model[r]=v;
    end endtask

    task rdchk(input [3:0] r); begin
        @(negedge clk); rs1=r; en=0; got=0;
        for(i=0;i<32;i=i+1) begin
            @(negedge clk); got[i]=o1; en=1;
        end
        @(negedge clk); en=0;
        tests=tests+1;
        if (got !== ((r==0)?32'd0:model[r])) begin errors=errors+1;
            if(errors<=5) $display("  RF MISMATCH r=%0d got=%h exp=%h", r, got, (r==0)?0:model[r]); end
    end endtask

    initial begin
        for(j=0;j<16;j=j+1) model[j]=0;
        @(negedge clk); rst=0;
        for(pass=0; pass<20; pass=pass+1) begin
            for(j=1;j<16;j=j+1) begin rv=$random; wr(j[3:0], rv); end
            for(j=0;j<16;j=j+1) rdchk(j[3:0]);
        end
        wr(4'd0, 32'hDEADBEEF); rdchk(4'd0);
        $display("serial_rf: %0d read-checks, %0d errors -> %s", tests, errors, errors?"FAIL":"PASS");
        $finish;
    end
endmodule
