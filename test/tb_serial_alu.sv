`default_nettype none
`timescale 1ns/1ps
// Thorough serial_alu test: for every op, stream many 32-bit operand pairs LSB
// first (edge cases + random) and check the assembled result and the final
// carry against a reference. Redundant on purpose: thousands of vectors.
module tb_serial_alu;
    import asicirific_pkg::*;
    logic clk=0, rst=1, init, en; alu_op_t op; logic a, b, y, cout;
    serial_alu dut(.clk(clk),.rst(rst),.init(init),.en(en),.op(op),.a(a),.b(b),.y(y),.last_cout(cout));
    always #5 clk=~clk;
    integer errors=0, tests=0;

    task automatic run(input alu_op_t o, input [31:0] va, input [31:0] vb,
                       output [31:0] res, output logic fcout);
        integer i; begin
            op=o; res=0;
            for (i=0;i<32;i=i+1) begin
                a=va[i]; b=vb[i]; init=(i==0); en=1;
                @(negedge clk); res[i]=y; if(i==31) fcout=cout;
                @(posedge clk);
            end
            en=0; init=0;
        end
    endtask

    function [31:0] ref_alu(input alu_op_t o, input [31:0] va, input [31:0] vb);
        case (o)
            ALU_ADD: ref_alu = va + vb;
            ALU_SUB: ref_alu = va - vb;
            ALU_AND: ref_alu = va & vb;
            ALU_OR:  ref_alu = va | vb;
            ALU_XOR: ref_alu = va ^ vb;
            default: ref_alu = va + vb;
        endcase
    endfunction

    logic [31:0] res, exp; logic fcout; integer k; alu_op_t ops[5];
    logic [31:0] edges[8];
    initial begin
        ops[0]=ALU_ADD; ops[1]=ALU_SUB; ops[2]=ALU_AND; ops[3]=ALU_OR; ops[4]=ALU_XOR;
        edges[0]=0; edges[1]=32'hFFFFFFFF; edges[2]=32'h80000000; edges[3]=32'h7FFFFFFF;
        edges[4]=1; edges[5]=32'h0000FFFF; edges[6]=32'hFFFF0000; edges[7]=32'h12345678;
        @(negedge clk); rst=0;
        // edge x edge for each op
        for (integer oi=0; oi<5; oi=oi+1)
          for (integer ei=0; ei<8; ei=ei+1)
            for (integer ej=0; ej<8; ej=ej+1) begin
                run(ops[oi], edges[ei], edges[ej], res, fcout);
                exp = ref_alu(ops[oi], edges[ei], edges[ej]); tests=tests+1;
                if (res !== exp) begin errors=errors+1;
                    $display("  MISMATCH op=%0d a=%h b=%h got=%h exp=%h", ops[oi], edges[ei], edges[ej], res, exp);
                end
            end
        // random vectors
        for (k=0;k<2000;k=k+1) begin
            logic [31:0] va, vb; integer oi;
            va=$random; vb=$random; oi=$random%5; if(oi<0) oi=-oi;
            run(ops[oi], va, vb, res, fcout);
            exp=ref_alu(ops[oi], va, vb); tests=tests+1;
            if (res !== exp) begin errors=errors+1;
                $display("  MISMATCH op=%0d a=%h b=%h got=%h exp=%h", ops[oi], va, vb, res, exp);
            end
        end
        $display("serial_alu: %0d tests, %0d errors -> %s", tests, errors, errors?"FAIL":"PASS");
        $finish;
    end
endmodule
